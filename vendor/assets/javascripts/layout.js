$(function() {

  if ($.fn.dcAccordion) {
    $('#nav-accordion').dcAccordion({
      eventType: 'click',
      autoClose: false,
      saveState: true,
      disableLink: true,
      speed: 'slow',
      showCount: false,
      autoExpand: true,
      classExpand: 'dcjq-current-parent'
    });
  }
});



