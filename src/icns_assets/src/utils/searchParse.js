const _parseSearchTerm = (term, validTld) => {
  let regex = /[^.]+$/;

  try {
    validateName(term);
  } catch (e) {
    return "invalid";
  }

  if (term.indexOf(".") !== -1) {
    const termArray = term.split(".");
    const tld = term.match(regex) ? term.match(regex)[0] : "";
    if (validTld) {
      if (tld === "icp" && termArray[termArray.length - 2].length < 3) {
        return "short";
      }
      return "supported";
    }

    return "unsupported";
  } else if (addressUtils.isAddress(term)) {
    return "address";
  } else {
    //check if the search term is actually a tld
    if (validTld) {
      return "tld";
    }
    return "search";
  }
};

function validateName(name) {
  const nameArray = name.split(".");
  const hasEmptyLabels = nameArray.filter((e) => e.length < 1).length > 0;
  if (hasEmptyLabels) throw new Error("Domain cannot have empty labels");
  const normalizedArray = nameArray.map((label) => {
    if (label === "[root]") {
      return label;
    } else {
      return isEncodedLabelhash(label) ? label : normalize(label);
    }
  });
  try {
    return normalizedArray.join(".");
  } catch (e) {
    throw e;
  }
}

export const parseSearchTerm = async (term) => {
  //   const ens = getENS();
  const domains = term.split(".");
  const tld = domains[domains.length - 1];
  try {
    validateName(tld);
  } catch (e) {
    return "invalid";
  }
  //   console.log("** parseSearchTerm", { ens });
  //   const address = await ens.getOwner(tld);
  return _parseSearchTerm(term, true);
};
