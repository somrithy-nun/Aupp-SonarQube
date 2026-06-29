const User = require("../models/user.model");

const createUser = async (data) => {
  return User.create(data);
};

const getUsers = async () => {
  return User.find();
};

const getUserById = async (id) => {
  return User.findById(id);
};

const updateUser = async (id, data) => {
  return User.findByIdAndUpdate(id, data, { new: true });
};

const deleteUser = async (id) => {
  return User.findByIdAndDelete(id);
};

module.exports = {
  createUser,
  getUsers,
  getUserById,
  updateUser,
  deleteUser
};