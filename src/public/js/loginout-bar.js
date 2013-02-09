var attemptLogout = function()
{
  var that = this;
  $.ajax({
    url: "/login",
    type: "POST",
    data: {logout : true},
    success: function(data){
      window.location.href="/";
    },
    error: function(jqXHR){
      console.log(jqXHR.responseText+' :: '+jqXHR.statusText);
    }
  });
}

$('#btn-logout').click(function(){ attemptLogout(); });

$('#btn-login-bar').click(function() {
  window.location.href="/login";
});

