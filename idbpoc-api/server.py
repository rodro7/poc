from flask import Flask, request
from flask_restful import Resource, Api
from sqlalchemy import create_engine
from json import dumps
from flask_jsonpify import jsonify
from news import News
from flask_cors import CORS
#db_connect = create_engine('sqlite:///chinook.db')
app = Flask(__name__);
api = Api(app);
CORS(app);
api.add_resource(News, '/news', '/news/','/news/<int:news_id>');
if __name__ == '__main__':
     app.run(port='5002')