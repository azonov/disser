#ifndef _H_ORIENTATION_PROCESSOR
#define _H_ORIENTATION_PROCESSOR

#include <cmath>
#include <vector>
#include <cstdlib>
#include "Coordinates.h"

namespace IndoorNavigation
{
    // Stores beacon information
    typedef struct BeaconInfo {
        int beaconId;
        Vector2D position;
        double errorStatSumRel = 0;
        double errorStatSumRelSquared = 0;
        int errorStatSumCount = 0;
        BeaconInfo(int beaconId, const Vector2D& position) : beaconId(beaconId), position(position) {}
    } BeaconInfo;
    
    // Processes acceleration and produces footsteps
    class FootstepProcessor
    {
        private :
            const double verticalAccThreshold = +1; // in m/s2 units  // TWEAK OR NOT?
            const double aboveThresholdDurationSec = 0.1; // sec
            const double belowThresholdDurationSec = 0.2; // sec
            const double gapDurationSec = 0.1; // sec
            const double maxTimeInBufferSec = 2; // sec
            std::vector<TimeVector3D> buffer = {};
            long lastAboveThresholdIdx = -1;

        public:
            //takes Time and 3D vector of measured acceleration (in m/s2 units). 
            //Z must be straight vertical, positive towards gravity, loose gravity component, e.g. AVG(Z) = 0
            //direction of X and Y must be fixed related to world (north pole)
            std::unique_ptr<struct TimeVector2D> AddAccelerationMeasurement(const TimeVector3D &acceleration);
    };


    //each signal from a beacon changes probability of being at various points of the plane.
    //we will store the fact of a signal from each beacon to build/update the probability picture.
    class BeaconTrace 
    {
        private:
            Vector2D _beaconPosition;
            double _distanceToBeacon; //radius (meters)
            double _distanceAccuracy; //sigma (meters)
            double _validity; //0..1, expresses belief in the values, fades out gradually

        public:
            BeaconTrace(const Vector2D& beaconPosition, double distanceToBeacon, double distanceAccuracy, double validity)
              : _beaconPosition(beaconPosition), _distanceToBeacon(distanceToBeacon), 
                _distanceAccuracy(distanceAccuracy <= 0 ? distanceToBeacon * 0.6 : distanceAccuracy),
                _validity(validity) { }
        
            //the historical picture should be modified - shifted along with expected movement of the device 
            //in accordance with inertial coordinate system (or other sources)
            void UpdateBeaconPosition(const Vector2D &positionAdditive) {
              _beaconPosition.x += positionAdditive.x;
              _beaconPosition.y += positionAdditive.y;
            }
            
            double GetProbabilityAt(const Vector2D &position) const;
                
            double GetVoteAt(const Vector2D &position) const;
        
            double GetValidity() const {
                return _validity;
            }
            
            //the validity of the history will fade in time
            void UpdateValidity(double validityMultiplier) {
              _validity *= validityMultiplier;
            }
    };

    // Keeps tracking current position of the object, updates this position with footsteps
    class OrientationProcessor
    {
        private:
            //orientation
            Quaternion _qPhoneToWorld = QuaternionZero();
            bool _verticalDirectionInitialized = false;
            bool _horizontalDirectionInitialized = false;
            double _gyroPrevTimeSec = -1;
            double _accPrevTimeSec = -1;
            double _magPrevTimeSec = -1;
            Vector3D _gyroZeroShiftRadSec = Vector3DMake(0,0,0);
            Vector3D _prevAccelerationPhone = Vector3DMake(0,0,0);
            Vector3D _accWorldLowPass = Vector3DMake(0,0,0);
            Vector3D _magWorldLowPass = Vector3DMake(0,0,0);
            Vector3D _magWorldBindingHorUnitVector = Vector3DMake(0,0,0);
            int _stationaryCounter = 0;
            int _magReadingsSmoothedCounter = 0;
            int _gravityReadingsSmoothedCounter = 0;
            const double _stationaryAccelerationThreshold = 0.05;
            const double _gyroZeroShiftSmoothCutoffFreq = 0.5;
            const double _gravitySmoothCutoffFreq = 0.1; //setting for smoothing gravity vector in World coord system
            const double _magneticSmoothCutoffFreq = 0.001; //setting for smoothing magnetometer vector // FOR TWEAKING
            const double _magneticMagnitudeMin = 30;
            const double _magneticMagnitudeMax = 65;
            //position
            FootstepProcessor _footstepProcessor = FootstepProcessor();
            Vector2D _position;
            double _positionAccuracy = 10;
            const double _positionAccuracyChangeCoef = 0.1; //(0..1) how fast the Accuracy is updated   // FOR TWEAKING
            const double _minPositionAccuracy = 2; //(m) min value for the position accuracy (sigma)  // FOR TWEAKING
            double _footstepLength = 0.85;  // FOR TWEAKING
            std::vector<BeaconInfo> _beaconInfos = {};
            std::vector<BeaconTrace> _beaconTraces = {};
            double _lastBeaconSignalTimeSec = 0;
            const double _traceDissipationRatePerSec = 0.90; //how slow the validity of past beacon signals fade out in time  // FOR TWEAKING
  
            void NewStepDetected(const TimeVector2D& direction);
            
            void NewBeaconSignalArrived(double timeSec, const Vector2D& beaconCoordinate, 
                double signalDistanceToBeacon, double signalDistanceAccuracy);
                    
            void AddBeaconSignalToHistory(double timeSec, const Vector2D& beaconCoordinate, 
                double signalDistanceToBeacon, double signalDistanceAccuracy);
                 
        public:
            OrientationProcessor() {
                _position = Vector2DMake(0, 0); //will be arbitrary selected later
                _positionAccuracy = -1; //means uncertainty, will be estimated later
            }

            // initializes original position (in meters) and accuracy of the position as Sigma in meters
            OrientationProcessor(Vector2D initialPosition, double positionAccuracySigmaM) 
                : _position(initialPosition), _positionAccuracy(positionAccuracySigmaM) {}

            // initializes original position (in meters) with accuracy of the position as Sigma in meters,
                // and magnetometer azimuth of Y axis for orientation binding
            OrientationProcessor(Vector2D initialPosition, double positionAccuracySigmaM, double magneticAzimuthAgainsYGrad)
                : _position(initialPosition), _positionAccuracy(positionAccuracySigmaM) 
            {
                double magneticAzimuthAgainsYRad = 3.1415 * magneticAzimuthAgainsYGrad / 180.0;
                _magWorldBindingHorUnitVector = Vector3DMake(sin(magneticAzimuthAgainsYRad), cos(magneticAzimuthAgainsYRad), 0);
            }

            // register a beacon position (as initialization)
            void AddBeaconInfo(int beaconId, const Vector2D &position) {
                _beaconInfos.push_back(BeaconInfo(beaconId, position));
            }

            //push new Acceleration reading in world-related coordinate system.
            //X,Y,Z must be in m/s2,
            //Z must be normalized (AVG(Z)=0),
            //Positive Z oriented towards gravity.
            //Current Position can change after this call.
            void NewAccelerationReadingWorld(const TimeVector3D &accelerationWorld);
                
            //push new Acceleration reading in phone-related coordinate system, 
            //XYZ must be in m/s2 and contain Gravity component.
            //positive Z is oriented towards gravity.
            void NewAccelerationReadingPhone(const TimeVector3D &accelerationPhone);
                
            //push new Angular Velosity sensor readings
            //XYZ must be in radians/second
            void NewGyroReading(const TimeVector3D &gyroPhone);
                
            void NewMagneticReadingPhone(const TimeVector3D &magPhone);
            
            //register each new signal from a Beacon
            //Current Position can change after this call.
            bool NewBeaconSignalArrived(double timeSec, int beaconId, double signalDistanceToBeacon);

            //a support function to convert RSSI into Distance (m)
            double GetDistanceFromRssi(double rssi) const;

            double GetVoteForPoint(const Vector2D &position) const;

            Vector3D ConvertVectorPhoneToWorld(const Vector3D &vector) {
                return QuaternionRotateVector(_qPhoneToWorld, vector);
            }

            std::unique_ptr<struct Vector2D> GetBestVotedPointAroundCurrentPosition() const;
            
            // Returns current position of the object in 2D coordinate system (X-Y).
            Vector2D GetPosition() const {
                return _position;
            }

            double GetPositionAccuracy() const {
                return _positionAccuracy;
            }
            
            //get current value of footstep length
            double GetFootstepLength() const {
                return _footstepLength;
            }
            
            //set value of footstep length
            void SetFootstepLength(double footstepLength) {
                _footstepLength = footstepLength;
            }
            
            Vector3D GetGyroZeroShiftRadSec() {
                return _gyroZeroShiftRadSec;
            }
            
            void SetGyroZeroShiftRadSec(const Vector3D& gyroZeroShiftRadSec) {
                _gyroZeroShiftRadSec = gyroZeroShiftRadSec;
            }

    };
}
#endif