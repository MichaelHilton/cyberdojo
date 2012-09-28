/*jsl:option explicit*/

var cyberDojo = (function($cd, $j) {

  $cd.loadFile = function(filename) {
    // I want to
    //    1. restore scrollTop and scrollLeft positions
    //    2. restore focus (also restores cursor position)
    // Restoring the focus loses the scrollTop/Left
    // positions so I have to save them in the dom so
    // I can set the back _after_ the call to focus()
    // The call to focus() allows you to carry on
    // typing at the point the cursor left off.
    $cd.saveScrollPosition($cd.currentFilename());
    $cd.fileDiv($cd.currentFilename()).hide();
    $cd.selectFileInFileList(filename);    
    $cd.fileDiv(filename).show();
    $cd.fileContentFor(filename).focus();
    $cd.restoreScrollPosition(filename);
    $j('#current_filename').val(filename);
  };
  
  //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  $cd.saveScrollPosition = function(filename) {
    var fc = $cd.fileContentFor(filename);
    var top = fc.scrollTop();
    var left = fc.scrollLeft();
    var div = $cd.fileDiv(filename);
    div.attr('scrollTop', top);
    div.attr('scrollLeft', left);
  };
  
  //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  $cd.restoreScrollPosition = function(filename) {
    // Restore the saved scrollTop/Left positions.
    // Note that doing the seemingly equivalent
    //   fc.scrollTop(top);
    //   fc.scrollLeft(left);
    // here does _not_ work. I use animate instead with a very fast duration==1
    var div = $cd.fileDiv(filename);
    var top = div.attr('scrollTop') || 0;
    var left = div.attr('scrollLeft') || 0;
    var fc = $cd.fileContentFor(filename);    
    fc.animate({scrollTop: top, scrollLeft: left}, 1);
  };
  
  //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  
  $cd.selectFileInFileList = function(filename) {    
    // Can't do $j('radio_' + filename) because filename
    // could contain characters that aren't strictly legal
    // characters in a dom node id
    // NB: This fails if the filename contains a double quote
    var node = $j('[id="radio_' + filename + '"]');
    var previousFilename = $cd.currentFilename();
    var previous = $j('[id="radio_' + previousFilename + '"]');
    $cd.radioEntrySwitch(previous, node);
    $cd.setRenameAndDeleteButtons(filename);
  };

  //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  $cd.setRenameAndDeleteButtons = function(filename) {
    var file_ops = $j('#file_operation_buttons');
    var renameFile = file_ops.find('#rename');
    var deleteFile = file_ops.find('#delete');

    if ($cd.cantBeRenamedOrDeleted(filename)) {
      renameFile.attr('disabled', true);
      renameFile.removeAttr('title');
      deleteFile.attr('disabled', true);
      deleteFile.removeAttr('title');
    } else {
      renameFile.removeAttr('disabled');
      renameFile.attr('title', 'Rename the current file');
      deleteFile.removeAttr('disabled');
      deleteFile.attr('title', 'Delete the current file');
    }    
  };

  //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  $cd.cantBeRenamedOrDeleted = function(filename) {
    var filenames = [ 'cyberdojo.sh', 'output' ];
    return $cd.inArray(filename, filenames);
  };
  
  //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  
  $cd.radioEntrySwitch = function(previous, current) {
    // Used by the run-tests-page filename radio-list
    // and also the create-page languages/exercises radio-lists
    // See the comment for makeFileListEntry() in
    // cyberdojo-files.js
    $cd.deselectRadioEntry(previous.parent());
    $cd.selectRadioEntry(current);
  };
  
  //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  $cd.loadNextFile = function() {
    var filenames = $cd.filenames().sort();
    var index = $j.inArray($cd.currentFilename(), filenames);
    var nextFilename = filenames[(index + 1) % filenames.length];
    $cd.loadFile(nextFilename);  
  };
    
  return $cd;
})(cyberDojo || {}, $);

