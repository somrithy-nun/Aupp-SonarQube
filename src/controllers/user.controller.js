const userService = require("../services/user.service");
const { createUserSchema, updateUserSchema } = require("../validations/user.validation");
const pick = require("../utils/pick");

const ALLOWED_FIELDS = ["name", "email", "age"];

const createUser = async (req, res, next) => {
  try {
    const { error } = createUserSchema.validate(req.body);

    if (error) {
      return res.status(400).json({ message: error.details[0].message });
    }

    const safeData = pick(req.body, ALLOWED_FIELDS);

    const user = await userService.createUser(safeData);

    res.status(201).json(user);
  } catch (err) {
    next(err);
  }
};

const updateUser = async (req, res, next) => {
  try {
    const { error } = updateUserSchema.validate(req.body);

    if (error) {
      return res.status(400).json({ message: error.details[0].message });
    }

    const safeData = pick(req.body, ALLOWED_FIELDS);

    const user = await userService.updateUser(req.params.id, safeData);

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json(user);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createUser,
  updateUser
};