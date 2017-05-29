#include "Coordinates.h"
#include <math.h>
#include <assert.h>
#include <stddef.h>

// Vector - Create

inline Vector2D Vector2DMake(double x, double y) {
    return (Vector2D) {
            .x = x,
            .y = y
    };
}

inline Vector3D Vector3DMake(double x, double y, double z) {
    return (Vector3D) {
            .x = x,
            .y = y,
            .z = z
    };
}

inline TimeVector2D TimeVector2DMake(double time, double x, double y) {
    return (TimeVector2D) {
            .x = x,
            .y = y,
            .time = time
    };
}

inline TimeVector3D TimeVector3DMake(double time, double x, double y, double z) {
    return (TimeVector3D) {
            .x = x,
            .y = y,
            .z = z,
            .time = time
    };
}

inline Vector3D Vector2DExtend(Vector2D v) {
    return (Vector3D) {
            .x = v.x,
            .y = v.y,
            .z = 0
    };
}

inline Vector2D Vector3DTrim(Vector3D v) {
    return (Vector2D) {
            .x = v.x,
            .y = v.y
    };
}


// Vector - Scalar products

inline double Vector2DScalarProduct(Vector2D v1, Vector2D v2) {
    return v1.x * v2.x + v1.y * v2.y;
}

inline double Vector3DScalarProduct(Vector3D v1, Vector3D v2) {
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
}

// Vector - Length

inline double Vector2DLength(Vector2D v) {
    return sqrt(Vector2DScalarProduct(v, v));
}

inline double Vector3DLength(Vector3D v) {
    return sqrt(Vector3DScalarProduct(v, v));
}

inline double Vector3DNorm1(Vector3D v) {
    return fabs(v.x) + fabs(v.y) + fabs(v.z);
}

inline double Vector3DIsZero(Vector3D v) {
    return v.x == 0 && v.y == 0 && v.z == 0;
}

// Vector - Multiplication by scalar, rotation by angle, reflection

inline void Vector3DMultiplyByScalar(Vector3D *v, double scalar) {
    assert(v != NULL);
    v->x *= scalar;
    v->y *= scalar;
    v->z *= scalar;
}

inline void Vector3DRotateZ(Vector3D *v, double angle) {
    assert(v != NULL);
    double x = v->x;
    double y = v->y;
    v->x = x * cos(angle) - y * sin(angle);
    v->y = x * sin(angle) + y * cos(angle);
}

inline void Vector3DReflectX(Vector3D *v) {
    assert(v != NULL);
    v->y = -v->y;
    v->z = -v->z;
}

inline void Vector3DReflectXY(Vector3D *v) {
    assert (v != NULL);
    v->z = -v->z;
}

// Vector - Add/Subtract

inline Vector3D Vector3DSum(Vector3D v1, Vector3D v2) {
    return (Vector3D) {
            .x = v1.x + v2.x,
            .y = v1.y + v2.y,
            .z = v1.z + v2.z
    };
}

inline Vector3D Vector3DDiff(Vector3D v1, Vector3D v2) {
    return (Vector3D) {
            .x = v1.x - v2.x,
            .y = v1.y - v2.y,
            .z = v1.z - v2.z
    };
}

// Vector - Aggregated add/subtract

inline void Vector3DAdd(Vector3D *v1, Vector3D v2) {
    v1->x += v2.x;
    v1->y += v2.y;
    v1->z += v2.z;
}

// Quaternion <---> Vector

inline Quaternion QuaternionZero() {
    return (Quaternion) {
            .x = 0,
            .y = 0,
            .z = 0,
            .w = 1
    };
}

inline Quaternion QuaternionFromAngleRad(Vector3D vector, double angleRad) {
    double module = Vector3DLength(vector);
    if (module == 0) {
        return QuaternionZero();
    }
    double sinA2 = sin(angleRad/2);
    return (Quaternion) {
            .x = sinA2 * vector.x / module,
            .y = sinA2 * vector.y / module,
            .z = sinA2 * vector.z / module,
            .w = cos(angleRad/2)
    };
}

inline Quaternion QuaternionFromUnitVectorToUnitVector(Vector3D a, Vector3D b, double proportion) {
    Vector3D rotationAxis = Vector3DMake(a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x);
    double rotationSin = Vector3DLength(rotationAxis);
    double rotationCos = a.x*b.x + a.y*b.y + a.z*b.z;
    if (rotationSin == 0 && rotationCos == 0) {
        return QuaternionZero();
    }
    if (rotationSin == 0 && rotationCos == 1) {
        return QuaternionZero();
    }
    if (rotationSin == 0 && rotationCos == -1) {
        return (Quaternion) {
                .x = sqrt(1/3),
                .y = sqrt(1/3),
                .z = sqrt(1/3),
                .w = 0
        };
    }
    rotationCos /= (Vector3DLength(a) * Vector3DLength(b));
    return QuaternionFromAngleRad(rotationAxis, proportion * acos(rotationCos));
}

inline Vector3D Vector3DFromQuaternion(Quaternion quaternion) {
    return (Vector3D){
            .x = quaternion.x,
            .y = quaternion.y,
            .z = quaternion.z
    };
}

inline Quaternion QuaternionFromVector3D(Vector3D vector) {
    return (Quaternion) {
            .x = vector.x,
            .y = vector.y,
            .z = vector.z,
            .w = 0
    };
}

inline Quaternion QuaternionConjugate(Quaternion q) {
    return (Quaternion) {
            .x = -q.x,
            .y = -q.y,
            .z = -q.z,
            .w = q.w
    };
}

inline Quaternion QuaternionMultiply(Quaternion q1, Quaternion q2) {
    return (Quaternion) {
            .x = q1.w*q2.x + q1.x*q2.w + q1.y*q2.z - q1.z*q2.y,
            .y = q1.w*q2.y + q1.y*q2.w + q1.z*q2.x - q1.x*q2.z,
            .z = q1.w*q2.z + q1.z*q2.w + q1.x*q2.y - q1.y*q2.x,
            .w = q1.w*q2.w - q1.x*q2.x - q1.y*q2.y - q1.z*q2.z
    };
}

inline Vector3D QuaternionRotateVector(Quaternion q, Vector3D v) {
    Quaternion r1 = QuaternionMultiply(q, QuaternionFromVector3D(v));
    Quaternion r2 = QuaternionMultiply(r1, QuaternionConjugate(q));
    return Vector3DFromQuaternion(r2);
}

inline Quaternion QuaternionConvertToOriginalSystem(Quaternion q, Quaternion qTransSystem0To1) {
    Quaternion r = QuaternionMultiply(QuaternionConjugate(qTransSystem0To1), q);
    return QuaternionMultiply(r, qTransSystem0To1);
}

inline Vector3D QuaternionGetAngles(Quaternion q) {
    double angle = 2 * acos(q.w);
    double sinThetaHalf = sqrt(1 - q.w*q.w);
    double k = angle / sinThetaHalf;
    return Vector3DMake(k * q.x, k * q.y, k * q.z);
}
