$(function(){

	console.log($("#simpleText"));
	console.log("init");

	var groupCollection = Backbone.Collection.extend({
  		url: 'http://localhost:3000/groups.json'
	});

	var groupList = new groupCollection

	groupList.fetch(
		{
			error: function(){
				console.log("some errors");
			},
			success: function(){
				console.log("it's ok");
				//1 sublime plugin (beautify js)
				//2 git aliases				
				//3 fix it
				//4 read: backbone view, model
				//5 crlf configuration
				//_.each(this.groupList, function(g){ console.log(g); });
				$("#simpleText").html("put groups from redmine");
			}
	});
});