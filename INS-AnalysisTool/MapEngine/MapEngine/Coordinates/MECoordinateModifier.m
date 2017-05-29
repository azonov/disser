#import "MECoordinateModifier.h"

inline double cdf(double x, double mu, double sigma) {
    return (1. + erf((x - mu) / (sigma * 1.414))) / 2.;
}

inline double GetAffection(double factDistance, double estDistance, double deviation) {
    return 1 - cdf(factDistance, estDistance, deviation) * 2;
}
