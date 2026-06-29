const Joi = require("joi");

const createUserSchema = Joi.object({
  name: Joi.string().min(2).max(50).required(),
  email: Joi.string().email().required(),
  age: Joi.number().min(0).optional()
});

const updateUserSchema = Joi.object({
  name: Joi.string().min(2).max(50),
  email: Joi.string().email(),
  age: Joi.number().min(0)
});

module.exports = {
  createUserSchema,
  updateUserSchema
};