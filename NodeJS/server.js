var express = require('express');
var bodyParser = require('body-parser');
var mongodb = require('mongodb');
var ObjectId = require('mongodb').ObjectID;
var host = '127.0.0.1';
var port = '27017'; // Default MongoDB port
var username = '';
var password = '';
var database = 'samplebmi';

// var connectionString = 'mongodb://' + user + ':' + password + '@' + host + ':' + port + '/' + database;
//comment the below line and uncomment the above line if you have a username and password.
var connectionString = 'mongodb://' + host + ':' + port + '/' + database;

// These will be set once connected, used by other functions below
var bmiRecords;

//CORS Middleware, causes Express to allow Cross-Origin Requests
var allowCrossDomain = function(req, res, next) {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE');
  res.header('Access-Control-Allow-Headers', 'Content-Type');

  next();
}

var app = express();

app.use(bodyParser.urlencoded({
  extended: true
}));
app.use(bodyParser.json());
app.use(allowCrossDomain);

mongodb.connect(connectionString, function(error, db) {
  if (error) {
    throw error;
  }

  bmiRecords = db.collection('bmiRecords');

  // Close the database connection and server when the application ends
  process.on('SIGTERM', function() {
    console.log("Shutting server down.");
    db.close();
    app.close();
  });

  var server = app.listen(4551, function() {
    console.log('Listening on port %d', server.address().port);
  });
});

// Creates a new bmi in the database
app.post('/store', function(request, response) {
  
  var bmiComp = request.body;
  
  bmiRecords.insert(bmiComp, function(err, result) {
    if (err) {
      return response.json(400, 'An error occurred creating this record.');
    }
    bmiRecords.find({}).toArray(function(err,resultArray){
      return response.json(200,resultArray);
    });
  });

});

// Retrieve a bmi's record from the database
app.get('/retrieve', function(request, response) {
  console.log('Retrieving records');
  bmiRecords.find({}).toArray(function(err,resultArray){
    return response.json(200,resultArray);
  });
});

// delete a bmi record from the database
app.post('/delete', function(request, response) {
  console.log('Deleting records');
  var body = request.body
  bmiRecords.remove({_id: ObjectId(body.id) }, function(err, result) {
    if (err) {
      return response.json(400, 'An error occurred when deleting this record.');
    }
    if(result.result.n == 1){
      return response.json(200, 'Record deleted successfully!');
    }
    else{
      return response.json(400, 'Could not save this record');
    }
    
  });
});
