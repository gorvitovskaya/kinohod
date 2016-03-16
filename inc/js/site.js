$('document').ready(function(){
	$( "button" ).button();

	$('#contentForm').ajaxForm({
        success:function(responseText, statusText, xhr, $form) { 
            $('#content').html(responseText);
            }
    });

	$( ".popup" ).click(function() {
		var ajaxFormPars = {
			success:function(responseText, statusText, xhr, $form) { 
	            currPlace.html(responseText);
	            $('#popupForm').ajaxForm(ajaxFormPars);

	        }
		};

		var currPlace = $( "#dialog" ).load($(this).attr('link'),function(){
			$('#popupForm').ajaxForm(ajaxFormPars);
		});
		var dialog = currPlace.dialog({
			overlay: { backgroundColor: "#000", opacity: 0.1 },
			modal: true,
			width: 500,
			buttons: [{ 
			      text: "Сохранить", 
			      click: function() { 
			      	$("#popupForm").append('<input type="hidden" name="save" value="1">');
			        $('#popupForm').submit();
			        var frm = $( "#contentForm" );
	            	if (frm.length > 0) {
	            		frm.append('<input type="hidden" name="reloadContent" value="1">');
	            		frm.submit();
	            	}
			      }
			   },{ 
			      text: "Закрыть", 
			      click: function() { 
			      	$( "#dialog" ).empty();
	            	dialog.dialog( "close" ); 
			      }
			   },]
		});
		

	});

	
});

function deleteImg(obj){
    var delID = $(obj).attr('del');
    var delText = $(obj).attr('deltext');
    var form = $(obj).closest("form");
    if(confirm(delText)) {
        form.append('<input type="hidden" name="del" value="'+delID+'">');
        form.submit();
    }
}