//FONCTION POUR AFFICHER OU CACHER UNE PARTIE D'UNE PAGE WEB

function DivStatus(image,id){
	  var Obj = document.getElementById(id);
	  var element = document.activeElement;
	  
	  if( Obj.style.visibility=="hidden")
	  {
		// Contenu cachÃ©, le montrer
		Obj.style.visibility ="visible";
		Obj.style.display ="block";
		element.blur();
		image.title='Hide informations';
		image.src = "./images/close.ico";
		image.innerHTML='&#53';
	  }
	  else
	  {
		// Contenu visible, le cacher
		Obj.style.visibility="hidden";
		Obj.style.display ="none";
		element.blur();
		image.title='Display informations';
		image.src = "./images/open.ico";
		image.innerHTML='&#54';
	  }
	}
	


	
	