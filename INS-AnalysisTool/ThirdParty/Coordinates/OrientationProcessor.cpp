#include "OrientationProcessor.h"


namespace
{
    // Vector - Add/Subtract, syntactic sugar. Defined in global namespace

    inline Vector3D operator - (const Vector3D& v1, const Vector3D& v2) {
        return (Vector3D) {
                .x = v1.x - v2.x,
                .y = v1.y - v2.y,
                .z = v1.z - v2.z
        };
    }

    inline Vector3D operator * (const Vector3D v, double c) {
        return (Vector3D) {
                .x = v.x * c,
                .y = v.y * c,
                .z = v.z * c
        };
    }

    inline Vector3D operator / (const Vector3D v, double d) {
        return (Vector3D) {
                .x = v.x / d,
                .y = v.y / d,
                .z = v.z / d
        };
    }
}

namespace IndoorNavigation
{
    // Low-pass filter implementation
    static Vector3D GetLowPassFiltered (const Vector3D& newValue, const Vector3D& lastValue, double cutoffFreqHz, double timeSecPastPrev) {
        if (timeSecPastPrev > 0) {
            double newValuePartMultiplier = (1./(1. + 1./(2*3.1415*cutoffFreqHz*timeSecPastPrev)));
            return Vector3DMake (
                    newValuePartMultiplier * newValue.x + (1-newValuePartMultiplier) * lastValue.x,
                    newValuePartMultiplier * newValue.y + (1-newValuePartMultiplier) * lastValue.y,
                    newValuePartMultiplier * newValue.z + (1-newValuePartMultiplier) * lastValue.z
            );
        } else {
            return lastValue;
        }
    }

}


namespace IndoorNavigation
{
   
    //FootstepProcessor ====================================================
    std::unique_ptr<struct TimeVector2D> FootstepProcessor::AddAccelerationMeasurement(const TimeVector3D &acceleration) {

        struct TimeVector2D *result = nullptr;

        buffer.push_back(acceleration);

        if (acceleration.z >= verticalAccThreshold) {
            lastAboveThresholdIdx = buffer.size() - 1;
        }

        if (lastAboveThresholdIdx >= 0 && acceleration.time - buffer[lastAboveThresholdIdx].time > gapDurationSec) {
            int firstAboveThresholdIdx;
            for (firstAboveThresholdIdx = 0; buffer[firstAboveThresholdIdx].z < verticalAccThreshold; firstAboveThresholdIdx++);
            double firstAboveThresholdTime = buffer[firstAboveThresholdIdx].time;
            double lastAboveThresholdTime = buffer[lastAboveThresholdIdx].time;
            double firstBelowTime = buffer[0].time;
            if (lastAboveThresholdTime - firstAboveThresholdTime > aboveThresholdDurationSec
                    && firstAboveThresholdTime - firstBelowTime > belowThresholdDurationSec) {
                //find a peak on the plato
                double maxValue = 0;
                int maxIdx = -1;
                for (int i = firstAboveThresholdIdx; i <= lastAboveThresholdIdx; i++)
                    if (buffer[i].z > maxValue) {
                        maxValue = buffer[i].z;
                        maxIdx = i;
                    }
                TimeVector3D peak = buffer[maxIdx];
                //guess movement directions
                double horModule = sqrt(peak.x * peak.x + peak.y * peak.y);
                result = new struct TimeVector2D(TimeVector2DMake(peak.time, -peak.x / horModule, -peak.y / horModule));
            }

            //remove processed data from the buffer
            buffer.erase(buffer.begin(), buffer.begin() + lastAboveThresholdIdx + 1);
            lastAboveThresholdIdx = -1;
        }

        //remove old extra history from the buffer
        double oldestTime = buffer[0].time;
        double lastTime = acceleration.time;
        if (oldestTime - lastTime > maxTimeInBufferSec) {
            //find the point to cut to
            int cuttingPointIdx;
            for (cuttingPointIdx = 0;
                 cuttingPointIdx < buffer.size() && lastTime - buffer[cuttingPointIdx].time > maxTimeInBufferSec;
                 cuttingPointIdx++);
            //do the trim
            buffer.erase(buffer.begin(), buffer.begin() + cuttingPointIdx);
            if (lastAboveThresholdIdx > 0 && lastAboveThresholdIdx < cuttingPointIdx) {
                cuttingPointIdx = -1;
            }
        }

        return std::unique_ptr<struct TimeVector2D>(result);
    }
    
    //BeaconTrace ==============================================
    
    double BeaconTrace::GetProbabilityAt(const Vector2D &position) const {
        if (_distanceToBeacon <= 0) 
            return 0;
        double dx = _beaconPosition.x - position.x;
        double dy = _beaconPosition.y - position.y;
        double positionToBeaconDistance = sqrt(dx*dx + dy*dy);
        double deviationFromCircle = fabs(positionToBeaconDistance - _distanceToBeacon);
        
        //calculating density of normal distribution for deviation against reported distances
        if (deviationFromCircle > 3*_distanceAccuracy)
            return 0;
        return _validity 
            * exp(-deviationFromCircle*deviationFromCircle/(2.0*_distanceAccuracy*_distanceAccuracy))
            / (_distanceAccuracy * sqrt(2.0 * 3.1416));
    }
    
    double BeaconTrace::GetVoteAt(const Vector2D &position) const {
        if (_distanceToBeacon <= 0) 
            return 0;
        double dx = _beaconPosition.x - position.x;
        double dy = _beaconPosition.y - position.y;
        double positionToBeaconDistance = sqrt(dx*dx + dy*dy);
        double deviationFromCircle = fabs(positionToBeaconDistance - _distanceToBeacon);
        
        //producing Gauss-shaped dome giving value 1 at zero deviation
        if (deviationFromCircle > 3*_distanceAccuracy)
            return 0;
        return _validity 
            * exp(-deviationFromCircle*deviationFromCircle/(2.0*_distanceAccuracy*_distanceAccuracy));
    }
    
    //OrientationProcessor =====================================================
    //NOTE: there is no GRAVITY component
    void OrientationProcessor::NewAccelerationReadingWorld(const TimeVector3D &accelerationWorld) {
        //pass the acceleration to Footstep Processor
        auto step = _footstepProcessor.AddAccelerationMeasurement(accelerationWorld);
        if (step) {
            NewStepDetected(*step);
        }
    }

    void OrientationProcessor::NewAccelerationReadingPhone(const TimeVector3D &accelerationPhone) {
        auto accVectorPhone = Vector3DMake(accelerationPhone.x, accelerationPhone.y, accelerationPhone.z);

        //initialize variable _gyroPrevTimeSec
        if (_accPrevTimeSec < 0) {
            _accPrevTimeSec = accelerationPhone.time;
            _prevAccelerationPhone = accVectorPhone;
            return;
        }
        
        //track Stationary state
        double accChangeModuleSinceLastAccRecord = Vector3DLength(_prevAccelerationPhone - accVectorPhone); //get Acc vector difference since last reading
        if (accChangeModuleSinceLastAccRecord < _stationaryAccelerationThreshold) {
            _stationaryCounter ++; 
//octave_stdout << "_stationaryCounter " << accelerationPhone.time << "\n";
        } else {
            _stationaryCounter = 0;
        }

        //convert the acceleration to World coordinate system
        auto accVectorWorld = QuaternionRotateVector(_qPhoneToWorld, accVectorPhone);
        
        _accWorldLowPass = GetLowPassFiltered(accVectorWorld, _accWorldLowPass, _gravitySmoothCutoffFreq, accelerationPhone.time - _accPrevTimeSec);
        _gravityReadingsSmoothedCounter ++;

        if (!_verticalDirectionInitialized) {  //initialize Vertical Orientation (set Z axis towards gravity)
            if (Vector3DLength(_accWorldLowPass) > 5) { //as soon as the module grows enough, given the low pass-freq of smoother
                auto gravityUnitVector = _accWorldLowPass / Vector3DLength(_accWorldLowPass);
                auto q = QuaternionFromUnitVectorToUnitVector(gravityUnitVector, Vector3DMake(0,0,1), 1);
                _qPhoneToWorld = QuaternionMultiply(q, _qPhoneToWorld);
                _magWorldLowPass = QuaternionRotateVector(q, _magWorldLowPass);
                _accWorldLowPass = QuaternionRotateVector(q, _accWorldLowPass);
                _verticalDirectionInitialized = true;
            }
        }
        else { //when vertical orientation initialized
            //correct orientation to keep Z vertical
            auto gravityUnitVector = _accWorldLowPass / Vector3DLength(_accWorldLowPass);
            auto verticalUnitVector = Vector3DMake(0,0,1);
            if (Vector3DNorm1(gravityUnitVector - verticalUnitVector) > 0.001) { //when the difference is notable
                auto q = QuaternionFromUnitVectorToUnitVector(gravityUnitVector, verticalUnitVector, 1);
                _qPhoneToWorld = QuaternionMultiply(q, _qPhoneToWorld);
                _accWorldLowPass = QuaternionRotateVector(q, _accWorldLowPass);
                _magWorldLowPass = QuaternionRotateVector(q, _magWorldLowPass);
            }
        } 
        
        if (_verticalDirectionInitialized && _horizontalDirectionInitialized) { //when the orientation completely initialized
            //pass the acceleration to Footstep Processor
            NewAccelerationReadingWorld(
                TimeVector3DMake(
                    accelerationPhone.time, accVectorWorld.x, accVectorWorld.y, accVectorWorld.z - 9.8));
        }
        
        _accPrevTimeSec = accelerationPhone.time;
        _prevAccelerationPhone = accVectorPhone;
    }
//octave_stdout << "_qPhoneToWorld=" << _qPhoneToWorld.x << " " <<  _qPhoneToWorld.y << " " << _qPhoneToWorld.z << " " << _qPhoneToWorld.w << "\n";

    
    void OrientationProcessor::NewGyroReading(const TimeVector3D &gyroPhone) {
        //initialize variable _gyroPrevTimeSec
        if (_gyroPrevTimeSec < 0) {
            _gyroPrevTimeSec = gyroPhone.time;
            return;
        }
        
        auto gyroVector = Vector3DMake(gyroPhone.x, gyroPhone.y, gyroPhone.z);
        double measurementDuration = gyroPhone.time - _gyroPrevTimeSec;
        
        //process the gyro vector
        auto angularSpeedRadSec = gyroVector - _gyroZeroShiftRadSec;
        auto angularMovementRad = angularSpeedRadSec * measurementDuration;
        double angularMovementModuleRad = Vector3DLength(angularMovementRad);
        //update current Phone-To-World transformation 
        if (angularMovementModuleRad > 0) {
            auto q = QuaternionFromAngleRad(angularMovementRad, angularMovementModuleRad);
            _qPhoneToWorld = QuaternionMultiply(_qPhoneToWorld, q);
        }
        
        //update last state
        if (_stationaryCounter > 5) {
            _gyroZeroShiftRadSec = GetLowPassFiltered(gyroVector, _gyroZeroShiftRadSec, _gyroZeroShiftSmoothCutoffFreq, measurementDuration);
        }
        _gyroPrevTimeSec = gyroPhone.time;
    }
    
    void OrientationProcessor::NewMagneticReadingPhone(const TimeVector3D &magPhone) {
        if (_magPrevTimeSec < 0) {
            _magPrevTimeSec = magPhone.time;
            return; //skip first reading
        }
        
        auto magVectorPhone = Vector3DMake(magPhone.x, magPhone.y, magPhone.z);
        double magMagnitude = Vector3DLength(magVectorPhone);
        if (magMagnitude < _magneticMagnitudeMin || magMagnitude > _magneticMagnitudeMax) {
            _magPrevTimeSec = magPhone.time;
            return; //skip reading if magnitude is not trustworthy
        }
        
        auto magVectorWorld = QuaternionRotateVector(_qPhoneToWorld, magVectorPhone);
        _magWorldLowPass = GetLowPassFiltered(magVectorWorld, _magWorldLowPass, _magneticSmoothCutoffFreq, magPhone.time - _magPrevTimeSec);
        
        if (_verticalDirectionInitialized)
        {
            //if desired magnetometer azimuth is defined
            if (!Vector3DIsZero(_magWorldBindingHorUnitVector)) { 
                double magWorldHorizontalModule = sqrt(_magWorldLowPass.x*_magWorldLowPass.x + _magWorldLowPass.y*_magWorldLowPass.y);
                auto magWorldHorizontalUnitVector = Vector3DMake(
                    _magWorldLowPass.x / magWorldHorizontalModule, 
                    _magWorldLowPass.y / magWorldHorizontalModule,
                    0);
                if (Vector3DNorm1(_magWorldBindingHorUnitVector-magWorldHorizontalUnitVector) > 0.01) { //when the difference is notable
                    auto q = QuaternionFromUnitVectorToUnitVector(magWorldHorizontalUnitVector, _magWorldBindingHorUnitVector, 1);
                    _qPhoneToWorld = QuaternionMultiply(q, _qPhoneToWorld);
                    _accWorldLowPass = QuaternionRotateVector(q, _accWorldLowPass);
                    _magWorldLowPass = QuaternionRotateVector(q, _magWorldLowPass);
                }
                _horizontalDirectionInitialized = true; //the orientation is initialized
                _magReadingsSmoothedCounter++;
            } 
            //if horizontal orientation was not defined - we take it so that Y keeps unchanged
            else if (Vector3DLength(_magWorldLowPass) > Vector3DLength(magVectorPhone) * 0.01) //as soon as accumulated module grows enough, given the low pass-freq of smoother
            {
                double magWorldHorizontalModule = sqrt(_magWorldLowPass.x*_magWorldLowPass.x + _magWorldLowPass.y*_magWorldLowPass.y);
                _magWorldBindingHorUnitVector = Vector3DMake(
                    _magWorldLowPass.x / magWorldHorizontalModule, 
                    _magWorldLowPass.y / magWorldHorizontalModule,
                    0);
//octave_stdout << "_horizontalDirectionInitialized " << magPhone.time << "\n";
            }
        }
        
        _magPrevTimeSec = magPhone.time;
    }
        
    bool OrientationProcessor::NewBeaconSignalArrived(double timeSec, int beaconId, double signalDistanceToBeacon) {
        //find the beacon info
        for (auto it = _beaconInfos.begin(); it != _beaconInfos.end(); ++it) {
            auto info = it;
            if (info->beaconId == beaconId) {
                //correct Distance according to statistics, get Accuracy from stat
                double signalDistanceAccuracy = -1; //unknown
                if (info->errorStatSumCount >= 5) {
                    //linear correction of Signal Distance according to stats
                    double errorCorrectionCoef = (info->errorStatSumRel / info->errorStatSumCount);
                    signalDistanceToBeacon /= errorCorrectionCoef;
                    //octave_stdout << "Beacon dist error correction Coef = " << errorCorrectionCoef << "\n";
                    //getting instance readings accuracy (Sigma) from stats
                    signalDistanceAccuracy = sqrt(info->errorStatSumRelSquared / info->errorStatSumCount)
                            * signalDistanceToBeacon;
                    //octave_stdout << "Beacon distance Sigma = " << signalDistanceAccuracy << "m\n";
                }
                //update the Beacon`s error stats
                double dx = _position.x - info->position.x;
                double dy = _position.y - info->position.y;
                double distanceToBeacon = sqrt(dx*dx + dy*dy);
                info->errorStatSumRel += (signalDistanceToBeacon/distanceToBeacon);
                double distanceErrorRelative = (signalDistanceToBeacon - distanceToBeacon)*2.0
                        /(signalDistanceToBeacon + distanceToBeacon);
                info->errorStatSumRelSquared += (distanceErrorRelative*distanceErrorRelative);
                info->errorStatSumCount ++;
                //add the signal to history
                NewBeaconSignalArrived(timeSec, info->position, signalDistanceToBeacon, signalDistanceAccuracy);
                return true;
            }
        }
        return false;
    }
   
    void OrientationProcessor::NewBeaconSignalArrived(double timeSec, const Vector2D& beaconCoordinate, 
        double signalDistanceToBeacon, double signalDistanceAccuracy) {
        //put the beacon signal into history log 
        AddBeaconSignalToHistory(timeSec, beaconCoordinate, signalDistanceToBeacon, signalDistanceAccuracy);
        
        //if current coordinate is not yet initialized - set it to a point between beacons
        if (_positionAccuracy < 0) {
            //get a point between beacons
            double x = 0, y = 0;
            for (auto it = _beaconInfos.begin(); it != _beaconInfos.end(); ++it) {
                x += it->position.x;
                y += it->position.y;
            }
            x /= _beaconInfos.size();
            y /= _beaconInfos.size();
            _position = Vector2DMake(x,y);
            //calculate a sigma to cover the beacons
            _positionAccuracy = 0;
            for (auto it = _beaconInfos.begin(); it != _beaconInfos.end(); ++it) {
                double dx = x - it->position.x;
                double dy = y - it->position.y;
                _positionAccuracy += (dx * dx + dy * dy);
            }
            _positionAccuracy = sqrt(_positionAccuracy / _beaconInfos.size()); // center-to-beacon distance STD
            _positionAccuracy += 20; //plus max distance of a beacon signal;
        }
            
        //get the most probable position according to beacon signals history
        //update current position according to the most probable position
        //update current position accuracy
        auto guessedPosition = GetBestVotedPointAroundCurrentPosition();
        if (guessedPosition) {
            auto newPosition = *guessedPosition;
            //calculate STD of new position against current position, update Position Accuracy (sigma)
            double dx = newPosition.x - _position.x;
            double dy = newPosition.y - _position.y;
            double deviation = sqrt(dx*dx + dy*dy);
//octave_stdout << "Deviation against beacon signals = " << deviation << "m\n";
            deviation = deviation < _minPositionAccuracy ? _minPositionAccuracy : deviation;
            _positionAccuracy = sqrt(_positionAccuracy*_positionAccuracy*(1-_positionAccuracyChangeCoef)
                + deviation*deviation*_positionAccuracyChangeCoef);
            //update current position
            _position = newPosition;
        }
    }
            
    void OrientationProcessor::AddBeaconSignalToHistory(double timeSec, const Vector2D& beaconCoordinate, 
        double signalDistanceToBeacon, double signalDistanceAccuracy) {
        //re-evaluate validity of the stored beacon traces, remove the traces with very low validity
        if (_beaconTraces.size() > 0) {
            double timeSinceLastBeaconSignal = timeSec - _lastBeaconSignalTimeSec;
            double validityMultiplier = pow(_traceDissipationRatePerSec, timeSinceLastBeaconSignal);
            for (auto it = _beaconTraces.begin(); it != _beaconTraces.end(); ++it) {
                it->UpdateValidity(validityMultiplier);
            }
            //find and remove the traces with Validity < 0.1
            for (;_beaconTraces.size() > 0 && _beaconTraces[0].GetValidity() < 0.1;
                _beaconTraces.erase(_beaconTraces.begin()));
        }
        
        _lastBeaconSignalTimeSec = timeSec;

        //add the recent trace into history
        BeaconTrace beaconTrace = BeaconTrace(beaconCoordinate, signalDistanceToBeacon, signalDistanceAccuracy, 1.0);
        _beaconTraces.push_back(beaconTrace);        
    }
    
    
    
    double OrientationProcessor::GetDistanceFromRssi(double rssi) const {
        if (rssi < 0) {
            double ratio = rssi / -59.0;
            double distanceM = (ratio < 1) 
                ? pow(ratio, 10)
                : 0.89976 * pow(ratio, 7.7095) + 0.111;
            distanceM *= 1.4; //based on experience (by DGarshin)
            return distanceM;
        }
        return 0;
    }
    
    
    double OrientationProcessor::GetVoteForPoint(const Vector2D &position) const {
        if (_beaconTraces.size() == 0)
            return 0;
        
        //sum votes of beacon traces (throughout stored history)
        double vote = 0;
        double denominator = 0;
        for (auto it = _beaconTraces.begin(); it != _beaconTraces.end(); ++it) {
            vote += it->GetVoteAt(position);
            denominator += it->GetValidity();
        }
        vote /= denominator;
        
        // multiply the vote by gaussian dome (with center at current position)
        // in order to avoid selecting extremums that are distant from current position
        double dx = position.x - _position.x;
        double dy = position.y - _position.y;
        double deviationFromCurrentPositionM = sqrt(dx*dx + dy*dy);
        double sigma = _positionAccuracy > 20 ? _positionAccuracy : 20; //set min threshold for the dome width
        vote *= exp(-deviationFromCurrentPositionM*deviationFromCurrentPositionM/(2.0*sigma*sigma));
        
        return vote;
    }
    
    std::unique_ptr<struct Vector2D> OrientationProcessor::GetBestVotedPointAroundCurrentPosition() const {
        if (_beaconTraces.size() < 3) {
            return std::unique_ptr<struct Vector2D>(nullptr);
        }

        double step = _footstepLength * 8;
        int maxStepsCount = 100; //decremental counter limiting absolute number of search steps
        double maxDeviationTotal = _positionAccuracy * 1.5; //decremental counter limiting the search area
        Vector2D result = _position;
        
        for (; step >= _footstepLength/4.0 && maxStepsCount > 0 && maxDeviationTotal > 0; maxStepsCount--) {
            double votes[9];
            //calculate votes for 8 positions around current position
            for (int i=0; i<9; i++) {
                double dx = (-1 + i / 3) * step;
                double dy = (-1 + i % 3) * step;
                Vector2D altPosition = Vector2DMake(result.x + dx, result.y + dy);
                votes[i] = GetVoteForPoint(altPosition);
            }
            //find a position with best vote
            int bestVoteIdx = 4; //default to index for non-deviated point (center)
            for (int i=0; i<9; i++) {
                if (i != bestVoteIdx && votes[i] > votes[bestVoteIdx]) {
                    bestVoteIdx = i;
                }
            }
            if (bestVoteIdx == 4) {
                //if default position won - we make step smaller
                step /= 2;
            } else {
                //alter coordinate to that point
                double dx = (-1 + bestVoteIdx / 3) * step;
                double dy = (-1 + bestVoteIdx % 3) * step;
                result = Vector2DMake(result.x + dx, result.y + dy);
                maxDeviationTotal -= sqrt(dx*dx + dy*dy);
            }
        }
        return std::unique_ptr<struct Vector2D>(new struct Vector2D(result));
    }
    
    
    void OrientationProcessor::NewStepDetected(const TimeVector2D& direction) {
        Vector2D shift = Vector2DMake(direction.x * _footstepLength, direction.y * _footstepLength);

        double deviation = sqrt(shift.x*shift.x + shift.y*shift.y);
        _positionAccuracy += deviation; //add the uncertainty to position accuracy

        //update current position with the new step
        _position.x += shift.x;
        _position.y += shift.y;

        //update history of beacon traces (signals)
        for (auto it = _beaconTraces.begin(); it != _beaconTraces.end(); ++it) {
            it->UpdateBeaconPosition(shift);
        }
    }
}
