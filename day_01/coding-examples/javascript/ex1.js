function add2(n1, n2) { 
  return n1 + n2;
}

function showResult(result) {
  console.log(result);
}

// this will be executed since it is not enclosed in a function when the file is loaded
var result = add2(2, 4);
showResult(result);
