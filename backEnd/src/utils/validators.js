exports.required = (v, field = "فیلد") => {
  if (v === undefined || v === null || String(v).trim() === "") {
    const err = new Error(`${field} الزامی است`);
    err.status = 400;
    throw err;
  }
  return v;
};
