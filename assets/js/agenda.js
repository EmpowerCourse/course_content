  function toggleDetails(elementId) {
    var targetDiv = document.getElementById(elementId);
    if (targetDiv.style.display !== 'block') {
      targetDiv.style.display = 'block';
    } else {
      targetDiv.style.display = 'none';
    }
  }
