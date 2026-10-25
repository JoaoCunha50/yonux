function parse(text) {
  let chips;
  try {
    const json = text.replace(/"(?:\\.|[^"\\])*"|-?Infinity|NaN/g, (token) =>
      token[0] === '"' ? token : "null",
    );
    chips = JSON.parse(json);
  } catch (error) {
    return -1;
  }
  if (!chips || typeof chips !== "object" || Array.isArray(chips)) return -1;

  let temperatures = [];
  for (const chip of Object.values(chips)) {
    if (!chip || typeof chip !== "object") continue;

    let preferred = [];
    let fallback = [];
    for (const [label, feature] of Object.entries(chip)) {
      if (!feature || typeof feature !== "object") continue;
      const readings =
        /^Package id \d+$/.test(label) || label === "Tdie"
          ? preferred
          : label === "Tctl"
            ? fallback
            : null;
      if (readings === null) continue;
      for (const [name, value] of Object.entries(feature)) {
        if (
          /^temp\d+_input$/.test(name) &&
          typeof value === "number" &&
          Number.isFinite(value)
        )
          readings.push(value);
      }
    }
    temperatures.push(...(preferred.length ? preferred : fallback));
  }
  return temperatures.length ? Math.round(Math.max(...temperatures)) : -1;
}
