#if defined __cplusplus
extern "C" {
#endif

// Look here for extern explanations: http://stackoverflow.com/questions/9334650/linker-error-calling-c-function-from-objective-c

#ifndef _H_COORDINATES
#define _H_COORDINATES

// Type definition for a 2D vector
typedef struct Vector2D {
    double x;
    double y;
} Vector2D;

typedef struct Vector2D Point2D;

// Type definition for a 3D vector
typedef struct Vector3D {
    double x;
    double y;
    double z;
} Vector3D;

typedef struct Vector3D Point3D;

// Type definition for a 2D vector with time

typedef struct TimeVector2D {
    double x;
    double y;
    double time;
} TimeVector2D;

// Type definition for a 3D vector with time

typedef struct TimeVector3D {
    double x;
    double y;
    double z;
    double time;
} TimeVector3D;

// Type definition for a quaternion
    
typedef struct Quaternion {
    double x;
    double y;
    double z;
    double w;
} Quaternion;

// Vector and point creation functions
extern Vector2D Vector2DMake(double x, double y);
extern Vector3D Vector3DMake(double x, double y, double z);
extern TimeVector2D TimeVector2DMake(double time, double x, double y);
extern TimeVector3D TimeVector3DMake(double time, double x, double y, double z);
extern Vector3D Vector2DExtend(Vector2D v);
extern Vector2D Vector3DTrim(Vector3D v);
#define Point2DMake Vector2DMake
#define Point3DMake Vector3DMake

// Vector manipulation functions - Scalar product
extern double Vector2DScalarProduct(Vector2D v1, Vector2D v2);
extern double Vector3DScalarProduct(Vector3D v1, Vector3D v2);

// Vector manipulation functions - Length
extern double Vector2DLength(Vector2D v);
extern double Vector3DLength(Vector3D v);
extern double Vector3DNorm1(Vector3D v);
extern double Vector3DIsZero(Vector3D v);

// Vector manipulation functions - Multiplication by scalar, rotation by angle, reflection
extern void Vector3DMultiplyByScalar(Vector3D *v, double scalar);
extern void Vector3DRotateZ(Vector3D *v, double angle);
extern void Vector3DReflectX(Vector3D *v);
extern void Vector3DReflectXY(Vector3D *v);

// Vector manipulation functions - Add/Subtract
extern Vector3D Vector3DSum(Vector3D v1, Vector3D v2);
extern Vector3D Vector3DDiff(Vector3D v1, Vector3D v2);

// Vector manipulation functions - Aggregated add/subtract
extern void Vector3DAdd(Vector3D *v1, Vector3D v2);

// Transformations between vectors and quaternions
extern Quaternion QuaternionZero();
extern Quaternion QuaternionFromAngleRad(Vector3D vector, double angleRad);
extern Quaternion QuaternionFromUnitVectorToUnitVector(Vector3D a, Vector3D b, double proportion);
extern Vector3D Vector3DFromQuaternion(Quaternion quaternion);
extern Quaternion QuaternionFromVector3D(Vector3D vector);
extern Quaternion QuaternionConjugate(Quaternion q);
extern Quaternion QuaternionMultiply(Quaternion q1, Quaternion q2);
extern Vector3D QuaternionRotateVector(Quaternion q, Vector3D v);
extern Quaternion QuaternionConvertToOriginalSystem(Quaternion q, Quaternion qTransSystem0To1);
extern Vector3D QuaternionGetAngles(Quaternion q);

#endif

#if defined __cplusplus
};
#endif