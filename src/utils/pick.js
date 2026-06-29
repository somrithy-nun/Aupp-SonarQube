const pick = (obj, allowedFields) => {
  const result = {};

  allowedFields.forEach((field) => {
    if (Object.prototype.hasOwnProperty.call(obj, field)) {
      result[field] = obj[field];
    }
  });

  return result;
};

module.exports = pick;