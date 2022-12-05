mat4 diag(vec4 a) {
    return mat4(
        a.x, 0, 0, 0,
        0, a.y, 0, 0,
        0, 0, a.z, 0,
        0, 0, 0, a.w
    );
}


/// Kerr metric in Kerr-Schild coordinates (black hole)
/// x -- 4d coordinate, x.x is the light-time
/// returns the metric tensor (matrix actually)
mat4 Metric(vec4 x) {
    const float a = 0.8;
    const float m = 1.0;
    const float Q = 0.0;
    const float cdist = 120.0;
    vec3 p = x.yzw;
    float rho = dot(p,p) - a*a;
    float r2 = 0.5*(rho + sqrt(rho*rho + 4.0*a*a*p.z*p.z));
    float r = sqrt(r2);
    vec4 k = vec4(1, (r*p.x + a*p.y)/(r2 + a*a), (r*p.y - a*p.x)/(r2 + a*a), p.z/r);
    float f = r2*(2.0*m*r - Q*Q)/(r2*r2 + a*a*p.z*p.z) * smoothstep(cdist*0.5, 0.0, r);
    return f*mat4(k.x*k, k.y*k, k.z*k, k.w*k)+diag(vec4(-1,1,1,1));
}

/// x -- 4d coordinate, x.x is the light-time
/// p -- 4d momentum
/// My speculation (probably wrong):
/// The change of a Hamiltonian with respect
/// to time is the change of momentum.
/// Answers the question: If the current
/// momentum is p, what will be the momentum
/// at coordinate x?
/// Geodesics are non-accelerated motion.
/// - null-geodesics correspod to particles which
/// have no mass / proper time, in other words,
/// which interval in 4d space-time is 0. Thus they
/// are called null geodesics. This is what will be
/// used in the ray-tracing, because light particles
/// have no mass. They correspond to cases when
/// A = 2 * Hamiltonian = 0
/// - space-like geodesics correspond to massive
/// particles, when the location is stationary or
/// constant, but the time flows. This is A > 0.
/// - time-like geodesics, when A < 0, are followed
/// by the so-called tachyons, which are theoretic
/// particles that move faster then light. In this
/// case, time is constant, position changes.
float Hamiltonian(vec4 x, vec4 p) {
    mat4 g_inv = inverse(Metric(x));
    return 0.5 * dot(g_inv * p, p);
}

/// x -- 4d coordinate, x.x is the light-time
/// dxdt -- coordinate derivative by time
/// In our case, this is a faster Hamiltonian.
float Lagrangian(vec4 x, vec4 dxdt) {
    return 0.5 * dot(Metric(x) * dxdt, dxdt);
}

/// x -- 4d coordinate, x.x is the light-time
/// p -- 4d momentum
/// Calculate the gradient of a Hamiltonian using
/// the Metric in every direction including time.
/// This gradient is the speed at which the momentum
/// momentally changes.
vec4 HamiltonianGradient(vec4 x, vec4 p) {
    const float eps = 0.001;
    return (
        vec4(
            Hamiltonian(x + vec4(eps, 0, 0, 0), p),
            Hamiltonian(x + vec4(0, eps, 0, 0), p),
            Hamiltonian(x + vec4(0, 0, eps, 0), p),
            Hamiltonian(x + vec4(0, 0, 0, eps), p)
        ) - Hamiltonian(x, p)
    ) / eps;
}

/// x -- 4d coordinate, x.x is the light-time
/// p -- 4d momentum
/// Perform one step of integration in-place
/// Steps in the direction of a gradient for p,
/// then using the new p steps for the coordinate x.
vec4 IntegrationStep(inout vec4 x, inout vec4 p) {
    const float TimeStep = 0.1;
    p = p - TimeStep * HamiltonianGradient(x, p);
    x = x + TimeStep * inverse(Metric(x)) * p;
}

/// x -- 4d coordinate, x.x is the light-time
/// ld -- light direction in 3d space.
/// Returns the 4d momentum of the light particle at
/// point x.
/// light follows a null-geodesic which is why this
/// function is called GetNullMomentum.
/// The light direction is normalised and is treated
/// like the momentous speed. The light speed is set
/// to 1. Yes, light particles carry momentum. In fact
/// the momentum of a light particle is related to
/// light frequency: lambda = h / p, where h is the
/// Planck constant, lambda is wavelength. In this
vec4 GetNullMomentum(vec4 x, vec3 ld) {
    return Metric(x) * vec4(1.0, normalize(ld));
}

/// x -- 4d coordinate, x.x is the light-time
/// p -- momentum vector
/// returns the momentous speed (dx/dt) of the
/// particle with momentum p that behaves according
/// to the metric, at point x in space-time
vec3 GetDirection(vec4 x, vec4 p) {
    vec4 dxdt = inverse(Metric(x)) * p;
    return normalize(dxdt.yzw);
}

/// trace a gedodesic a
void TraceGeodesic(inout float time, inout vec3 pos, inout vec3 ld) {
    vec4 x = vec4(time, pos);
    vec4 p = GetNullMomentum(ld);

    const int steps = 256;
    for (int i = 0; i < steps; i++) {
        IntegrationStep(x, p);
        //you can add a stop condition here when x is below the event horizon for example
    }

    pos = x.yzw;
    time = x.x;
    ld = GetDirection(p);
}