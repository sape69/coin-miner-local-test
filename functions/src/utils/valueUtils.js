"use strict";

// ============================================================
// 🐱 STELLURIINI - VALUE UTILITIES
// ============================================================
//
// Yleiset lukuarvojen ja aikaleimojen apufunktiot.
//
// ============================================================

// ============================================================
// NUMBER HELPERS
// ============================================================

function number(value, fallback = 0) {
const result = Number(value);

return Number.isFinite(result)
? result
: fallback;
}

function nonNegative(value, fallback = 0) {
const result = Number(value);

return Number.isFinite(result) && result >= 0
? result
: fallback;
}

function positive(value, fallback = 0) {
const result = Number(value);

return Number.isFinite(result) && result > 0
? result
: fallback;
}

// ============================================================
// TIMESTAMP HELPER
// ============================================================

function timestampMs(value) {
if (!value) {
return 0;
}

if (typeof value.toMillis === "function") {
try {
const milliseconds = value.toMillis();

  return Number.isFinite(milliseconds)
    ? milliseconds
    : 0;
} catch (_) {
  return 0;
}

}

if (typeof value.toDate === "function") {
try {
const date = value.toDate();

  return date instanceof Date &&
    Number.isFinite(date.getTime())
    ? date.getTime()
    : 0;
} catch (_) {
  return 0;
}

}

if (value instanceof Date) {
return Number.isFinite(value.getTime())
? value.getTime()
: 0;
}

if (typeof value === "string") {
const milliseconds = new Date(value).getTime();

return Number.isFinite(milliseconds)
  ? milliseconds
  : 0;

}

if (
typeof value === "number" &&
Number.isFinite(value)
) {
return value;
}

return 0;
}

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
number,
nonNegative,
positive,
timestampMs,
};