package authorization

# Default deny all access
default allow = false

# Helper to get user roles from JWT token
user_roles[role] {
    role := input.user.roles[_]
}

# Helper to get user groups from JWT token
user_groups[group] {
    group := input.user.groups[_]
}

# Helper to check if user has required role
has_role(required_role) {
    user_roles[role]
    role == required_role
}

# Helper to check if user has any of the required roles
has_any_role(required_roles) {
    user_roles[role]
    required_roles[role]
}

# Helper to check if user belongs to required group
has_group(required_group) {
    user_groups[group]
    group == required_group
}

# Helper to check time-based access
within_working_hours {
    time.now_ns() < time.parse_rfc3339_ns("2025-12-31T17:00:00Z")
    time.now_ns() > time.parse_rfc3339_ns("2025-12-31T09:00:00Z")
}

# Helper to check IP-based access
allowed_network(ip) {
    net.cidr_contains("10.0.0.0/8", ip)
}

allowed_network(ip) {
    net.cidr_contains("172.16.0.0/12", ip)
}

allowed_network(ip) {
    net.cidr_contains("192.168.0.0/16", ip)
}

# Allow access based on role and resource
allow {
    # Check if user has admin role
    has_role("admin")
    
    # Verify working hours for sensitive operations
    within_working_hours
    
    # Verify network access
    allowed_network(input.request.source_ip)
    
    # Additional security checks
    input.request.protocol == "https"
    input.request.authenticated == true
    input.request.mfa_verified == true
}

# Allow developer access to specific resources
allow {
    # Check if user has developer role
    has_role("developer")
    
    # Verify team membership
    input.user.team == input.resource.team
    
    # Verify environment access
    input.resource.environment == "development"
    
    # Verify working hours
    within_working_hours
    
    # Verify network access
    allowed_network(input.request.source_ip)
    
    # Additional security checks
    input.request.protocol == "https"
    input.request.authenticated == true
    input.request.mfa_verified == true
}

# Allow auditor read-only access
allow {
    # Check if user has auditor role
    has_role("auditor")
    
    # Verify read-only operation
    input.request.method == "GET"
    
    # Verify working hours
    within_working_hours
    
    # Verify network access
    allowed_network(input.request.source_ip)
    
    # Additional security checks
    input.request.protocol == "https"
    input.request.authenticated == true
    input.request.mfa_verified == true
}

# Emergency access policy
allow {
    # Check if user has emergency role
    has_role("emergency_access")
    
    # Verify incident is active
    input.context.incident_id != null
    
    # Verify approval exists
    input.context.emergency_approved == true
    
    # Log emergency access
    trace(sprintf("Emergency access granted to %v for incident %v", 
                 [input.user.name, input.context.incident_id]))
}

# Allow service account access
allow {
    # Verify service account authentication
    input.user.type == "service_account"
    
    # Verify service account roles
    has_any_role(input.resource.allowed_service_accounts)
    
    # Verify network access
    allowed_network(input.request.source_ip)
    
    # Additional security checks
    input.request.protocol == "https"
    input.request.authenticated == true
}

# Deny access if MFA is not verified
deny {
    input.request.mfa_verified == false
}

# Deny access outside working hours
deny {
    not within_working_hours
}

# Deny access from unauthorized networks
deny {
    not allowed_network(input.request.source_ip)
}

# Deny if required security headers are missing
deny {
    input.request.headers["Content-Security-Policy"] == null
}

deny {
    input.request.headers["X-Frame-Options"] == null
}

# Audit logging for all access attempts
audit[message] {
    message := {
        "timestamp": time.now_ns(),
        "user": input.user.name,
        "roles": user_roles,
        "groups": user_groups,
        "resource": input.resource,
        "action": input.request.method,
        "allowed": allow,
        "source_ip": input.request.source_ip,
        "context": input.context
    }
}

# Violation reporting
violations[violation] {
    not allowed_network(input.request.source_ip)
    violation := {
        "type": "network_violation",
        "description": "Access attempted from unauthorized network",
        "source_ip": input.request.source_ip
    }
}

violations[violation] {
    not within_working_hours
    violation := {
        "type": "time_violation",
        "description": "Access attempted outside working hours",
        "timestamp": time.now_ns()
    }
}

violations[violation] {
    input.request.mfa_verified == false
    violation := {
        "type": "mfa_violation",
        "description": "Access attempted without MFA verification",
        "user": input.user.name
    }
}
