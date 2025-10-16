//Role based acces

// src/middleware/roleAuth.js
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res
        .status(403)
        .json({
          message: `User role ${req.user.role} is not authorized for this action`,
        });
    }
    next();
  };
};

export default authorize;
