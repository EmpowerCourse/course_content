var Beverage = require('../models/beverage');

exports.index = function(req, res, next) {
  Beverage.find({}).exec(function(err, items) {
  		if (err) return next(err);
		res.render('beverages/index', { 
			title: 'Our current beverage offerings',
		  	list: items
		});
  	});
  // Beverage.find() // optional where criteria can be passed here
  // 	.limit(20)
  // 	.sort({name: -1})
  // 	.select('name description')
  // 	.exec(function(err, items) {
  // 		if (err) return next(err);
  // 		console.log(items);
		// res.render('beverages/index', { 
		// 	title: 'Our current beverage offerings',
		//   	list: items
		// });
  // 	});
};

exports.add = function(req, res, next) {
	var item = { name: req.body.name, description: req.body.description };
	// var bev;
	// if (req.body.id) {
	// 	bev = Beverage.findById(obj._id, function (err, doc){
	// 	  // doc is a Document
	// 	});
	// }
	if (req.body.id === '') { 
		new Beverage(item).save(function (err) {
		  if (err) return next(err);
		  console.log('inserted');
		  res.redirect('/catalog/beverages');
		});
	} else {
		Beverage.update({_id: req.body.id}, item, function (err) {
		  if (err) return next(err);
		  console.log('updated');
		  res.redirect('/catalog/beverages');
		});
	}
};

exports.delete = function(req, res, next) {
	Beverage.findByIdAndRemove(req.params.id, (err, b) => {  
      if (err) return next(err);
      console.log('removed ' + b._id);
	  res.redirect('/catalog/beverages');
	});
};
