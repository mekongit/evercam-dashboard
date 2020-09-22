NProgress.configure({
  showSpinner: false,
  ease: 'ease',
  speed: 500
});

$(window).ready(function() {
  NProgress.start();
});
$(window).load(function(){
	NProgress.done();
});
