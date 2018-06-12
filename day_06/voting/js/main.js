// just setting the url for the call and putting it into a variable
var apiRootUrl = 'http://voteapi.empower2018.us';

function bindClickEvents(){

  var getGithubName = function(){
    var githubName = $('#user-name').val();
    if (!githubName) {
      displayData(' - Warning','<div class="alert alert-danger" style="margin-bottom: 0;" role="alert">Enter your github name in, please.</div>');
      return null;
    }
    return githubName;
  };

  var setResultsType = function(resultsType){
    $('#results-type').html(resultsType);
  };

  var displayData = function(resultsType, data){
    $('#data-container').hide();
    $('#data-container').html(data);
    $('#data-container').fadeIn(2000);
    setResultsType(resultsType);
  };

  $('#show-options').click(function(){
    $.get(apiRootUrl + '/apis', function(data){
      //use underscore to sort data by vote_count and then reverse array to show
      data = _.sortBy(data, 'name');
      var optionData = '';
      for (var i = 0; i < data.length; i++) {
        optionData += "<p>" + data[i].name + "</p>";
      }
      displayData(' - Options', optionData);
    });
  });

  $('#show-tally').click(function(){
    $.get(apiRootUrl + '/tally', function(data){
      //use underscore to sort data by vote_count and then reverse array to show
      //highest vote count first
      data = _.sortBy(data, 'vote_count').reverse();
      var optionData = '';
      for (var i = 0; i < data.length; i++) {
        optionData += "<p>" + data[i].api_name + ": " + data[i].vote_count + "</p>";
      }
      displayData(' - Tally', optionData);
    });
  });

  $('#show-vote').click(function(){
    var name = getGithubName();
    if (!name) {
      return;
    }

    $.get(apiRootUrl + '/' + name + '/vote', function(data){
      var message = '';
      if (data && data.success) {
        message = 'You voted for: ' + data.message.api_name;
      }
      else{
        message = 'You have not voted yet!';
      }
      displayData(' - Your Vote', message);
    });
  });

  $('#do-vote').click(function(){
    var name = getGithubName();
    if (!name) {
      return;
    }

    var api = $('#api-name').val();

    $.post(apiRootUrl + '/' + name + '/vote',
      {"api_name":api},
      function(data){
        if (data && data.success) {
          displayData(' - Voted','<div class="alert alert-success" style="margin-bottom: 0;" role="alert">You have voted for ' + api + '.</div>');
        }
        else{
          displayData(' - Vote Failed','<div class="alert alert-warning" style="margin-bottom: 0;" role="alert">Your vote failed: ' + data.message + '.</div>');
        }
      }
    );
  });

  $("#reset-vote").click(function(){
    var name = getGithubName();
    if (!name) {
      return;
    }

    var options = {
      url: apiRootUrl + '/' + name + '/vote',
      type: 'DELETE',
      success: function(data){
        displayData(' - Reset','<div class="alert alert-success" style="margin-bottom: 0;" role="alert">Your vote has been reset.</div>');
      }
    };
    $.ajax(options);
  });
};
