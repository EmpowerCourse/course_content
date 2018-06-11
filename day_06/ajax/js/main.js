// just setting the url for the call and putting it into a variable
var apiUrl = 'http://worldclockapi.com/api/json/est/now';

function bindClickEvent(){
  $('#get-time').click(function(){
    //getTimeWithAjax();
    getTimeUsingGet();
  });
};

function getTimeStringFromData(data){
  return 'It is ' + data.dayOfTheWeek + '.  The time is ' + data.currentDateTime + ' (' + data.timeZoneName + ')';
}

function getTimeWithAjax(){
  // using the .ajax method to get the time
  $.ajax(apiUrl,{
    method: 'GET'
  })
  .done(function(data) {
    // this callback will run when the ajax call is done
    console.log('got the data');
    console.log(data);
    $('#time-container').html(getTimeStringFromData(data));
  })
  .fail(function() {
    // this happens when the ajax call fails
    console.log('failure');
  })
  .always(function() {
    // this always happens if there is a successful call or a failed call
    console.log('this always happens');
  });;
}

function getTimeUsingGet(){
  // .get is a shortcut to using ajax when doing a get
  // you can sometimes get away with just the url and a callback
  $.get(apiUrl, function(data){
    $('#time-container').html(getTimeStringFromData(data));
  });
}
