// roleMiddleware.js

// Optional role hierarchy
const roleHierarchy = {
  superadmin: 3,
  admin: 2,
  manager: 1,
  user: 0,
};

/**
 * Middleware to authorize users by roles and optionally permissions
 * @param {Object} options
 * @param {Array<string>} options.roles - Allowed roles
 * @param {Array<string>} [options.permissions] - Optional required permissions
 */
export const authorize = ({ roles = [], permissions = [] } = {}) => {
  return (req, res, next) => {
    const user = req.user;

    if (!user) {
      return res.status(401).json({ message: "Unauthorized: No user found" });
    }

    const userRoles = Array.isArray(user.roles) ? user.roles : [user.role];
    const userPermissions = Array.isArray(user.permissions) ? user.permissions : [];

    // Check if user has any of the allowed roles
    const hasRequiredRole = roles.some((role) => {
      return userRoles.includes(role) || hasHigherRole(userRoles, role);
    });

    if (!hasRequiredRole) {
      return res.status(403).json({
        message: `Forbidden: Required role(s): [${roles.join(", ")}]`,
      });
    }

    // If permissions are required, check them
    const hasRequiredPermissions = permissions.every((perm) =>
      userPermissions.includes(perm)
    );

    if (permissions.length > 0 && !hasRequiredPermissions) {
      return res.status(403).json({
        message: `Forbidden: Missing permission(s): [${permissions.join(", ")}]`,
      });
    }

    // All good
    next();
  };
};

/**
 * Checks if the user has a higher role than required
 * @param {string[]} userRoles
 * @param {string} requiredRole
 * @returns {boolean}
 */
function hasHigherRole(userRoles, requiredRole) {
  const requiredLevel = roleHierarchy[requiredRole];

  return userRoles.some((role) => {
    const userLevel = roleHierarchy[role];
    return userLevel >= requiredLevel;
  });
}
