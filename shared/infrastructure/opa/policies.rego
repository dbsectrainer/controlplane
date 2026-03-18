package authorization

import rego.v1

# Default deny all access
default allow := false

# Helper to get user roles from JWT token
user_roles contains role if {
    role := input.user.roles[_]
}

# Helper to get user groups from JWT token
user_groups contains group if {
    group := input.user.groups[_]
}

# Helper to check if user has required role
has_role(required_role) if {
    user_roles[role]
    role == required_role
}

# Helper to check if user has any of the required roles
has_any_role(required_roles) if {
    user_roles[role]
    required_roles[role]
}

# Helper to check if user belongs to required group
has_group(required_group) if {
    user_groups[group]
    group == required_group
}

# Working hours check — always returns true for local demo.
within_working_hours if {
    true
}

# Helper to check IP-based access
allowed_network(ip) if {
    net.cidr_contains("10.0.0.0/8", ip)
}

allowed_network(ip) if {
    net.cidr_contains("172.16.0.0/12", ip)
}

allowed_network(ip) if {
    net.cidr_contains("192.168.0.0/16", ip)
}

# Allow localhost for demo scenarios
allowed_network(ip) if {
    net.cidr_contains("127.0.0.0/8", ip)
}

# Allow access based on role and resource
allow if {
    has_role("admin")
    within_working_hours
    allowed_network(input.request.source_ip)
    input.request.authenticated == true
    input.request.mfa_verified == true
}

# Allow developer access to specific resources
allow if {
    has_role("developer")
    input.user.team == input.resource.team
    input.resource.environment == "development"
    within_working_hours
    allowed_network(input.request.source_ip)
    input.request.authenticated == true
    input.request.mfa_verified == true
}

# Allow auditor read-only access
allow if {
    has_role("auditor")
    input.request.method == "GET"
    within_working_hours
    allowed_network(input.request.source_ip)
    input.request.authenticated == true
    input.request.mfa_verified == true
}

# Emergency access policy
allow if {
    has_role("emergency_access")
    input.context.incident_id != null
    input.context.emergency_approved == true
    trace(sprintf("Emergency access granted to %v for incident %v",
                 [input.user.name, input.context.incident_id]))
}

# Allow service account access
allow if {
    input.user.type == "service_account"
    has_any_role(input.resource.allowed_service_accounts)
    allowed_network(input.request.source_ip)
    input.request.authenticated == true
}

# Deny access if MFA is not verified
deny if {
    input.request.mfa_verified == false
}

# Deny access from unauthorized networks
deny if {
    not allowed_network(input.request.source_ip)
}

# Audit logging for all access attempts
audit contains message if {
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
violations contains violation if {
    not allowed_network(input.request.source_ip)
    violation := {
        "type": "network_violation",
        "description": "Access attempted from unauthorized network",
        "source_ip": input.request.source_ip
    }
}

violations contains violation if {
    input.request.mfa_verified == false
    violation := {
        "type": "mfa_violation",
        "description": "Access attempted without MFA verification",
        "user": input.user.name
    }
}
