var showMe = function(){
  $('.hideme').show();
};

function hideMe(){
  $('.hideme').fadeOut(2000);
};

var toggleShrink = function(finalOpacity){
  $( ".hideme" ).animate({
      opacity: finalOpacity,
      left: "+=50",
      height: "toggle"
    }, 5000, function() {
      // do stuff then the Animation is complete.
    });
};

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
