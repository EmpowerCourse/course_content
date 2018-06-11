//this is one way to define a function, just assign an anonymous function to a
// variable to be called later - the variable needs to be in the same scope as the
// calling code
var showMe = function(){
  $('.hideme').fadeIn(1000);
};

function hideMe(){
  $('.hideme').fadeOut(2000);
};

// since this animation is a toggle on height, we can re-use it to shink and to grow
// the divs, just passing in a different final opacity for the animate function to use
var toggleShrink = function(finalOpacity){
  $( ".hideme" ).animate({
      opacity: finalOpacity,
      left: "+=50",
      height: "toggle"
    }, 3000, function() {
      // do stuff then the Animation is complete.
    });
};

// this function is called when the page loads and it wires up all of the click
// events for the buttons
var initializePage = function(){
  $('#hide-me').click(function(){
    hideMe();
  });

  $('#show-me').click(function(){
    showMe();
  });

  $('#shrink-me').click(function(){
    toggleShrink(.25);
  });

  $('#grow-me').click(function(){
    toggleShrink(1);
  });
};
