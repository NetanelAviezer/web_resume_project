from db import db
from datetime import datetime

class Like(db.Model):
    __tablename__ = "likes_table" 
    id = db.Column(db.Integer, primary_key=True)

class Comment(db.Model):
    __tablename__ = "comment_table"
    id = db.Column(db.Integer, primary_key=True)
    text = db.Column(db.Text, nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)
