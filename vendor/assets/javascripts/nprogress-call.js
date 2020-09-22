var nprogressCall = function () {

	$(document).on('page:fetch', function() {
	  NProgress.start();
	  console.log("HI start");
	});

	$(document).on('page:receive', function() {
	  NProgress.done();
	  console.log("HI done")
	});

	$(document).on('page:restore', function() {
	  NProgress.remove();
	  console.log("HI remove")
	});

}
