from flask_restful import fields, reqparse, request, Resource
import json
import sys
json_data = dict(json.loads(open('news.json').read()))["data"];
post_parser = reqparse.RequestParser();
post_parser.add_argument(
    'source', dest='source',
    location='form', required=True
)
class News(Resource):
	def _findWhere(self, list, news_id):
		if news_id == "":
			return list;
		else:
			return [dict(x) for x in list if dict(x)["id"] == news_id];
	def _filter(self, list, news_id):
		return [dict(x) for x in list if dict(x)["id"] != news_id];

	def get(self, news_id:str = ""):
		return self._findWhere(json_data, news_id);
	 
	def delete(self, news_id):
		global json_data
		json_data = self._filter(json_data, news_id)
		return json_data;

	def post(self):
		global json_data
		json_data.insert(0, request.get_json());
		return request.get_json();

	def put(self):
		global json_data
		update = request.get_json();
		for index, obj in enumerate(json_data):
			if obj["id"] == update["id"]:
				json_data[index] = update;
		return request.get_json();