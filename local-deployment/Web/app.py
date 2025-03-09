from flask import Flask, render_template, request, jsonify
from db import db
from models import Like, Comment
from datetime import datetime, timedelta
from sqlalchemy import func
import os
import time

app = Flask(__name__)

# Database configuration with fallbacks
db_host = os.environ.get('DB_HOST', 'resume_db')
db_port = os.environ.get('DB_PORT', '5432')
db_user = os.environ.get('DB_USER', 'user')
db_password = os.environ.get('DB_PASSWORD', 'password')
db_name = os.environ.get('DB_NAME', 'resume_db')

# Build connection string
try:
    db_uri = f'postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}'
    print(f"Connecting to database: {db_host}:{db_port}/{db_name} as {db_user}")
except Exception as e:
    print(f"Error building connection string: {e}")
    db_uri = 'postgresql://user:password@resume_db:5432/resume_db'
    print("Using default connection string")

app.config['SQLALCHEMY_DATABASE_URI'] = db_uri
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db.init_app(app)

# Function to try database connection with retry
def setup_database(max_retries=10, retry_delay=3):
    retries = 0
    while retries < max_retries:
        try:
            with app.app_context():
                # Create tables if they don't exist
                db.create_all()
                print("✅ Database connection successful. Tables created or verified.")
                return True
        except Exception as e:
            retries += 1
            print(f"⚠️ Database connection attempt {retries} failed: {e}")
            if retries < max_retries:
                print(f"Retrying in {retry_delay} seconds...")
                time.sleep(retry_delay)
            else:
                print("❌ Max retries reached. Database setup failed.")
                return False

# Try to set up the database
setup_database()

@app.route("/")
def index():
    try:
        like_count = Like.query.count()
        comments = Comment.query.order_by(Comment.timestamp.desc()).all()
        return render_template("index.html", like_count=like_count, comments=comments)
    except Exception as e:
        print(f"Error in index route: {e}")
        # Return the template with empty data if there's a database error
        return render_template("index.html", like_count=0, comments=[])

@app.route("/like", methods=["POST"])
def like():
    try:
        new_like = Like()
        db.session.add(new_like)
        db.session.commit()
        like_count = Like.query.count()
        return jsonify({"like_count": like_count})
    except Exception as e:
        print(f"Error in like route: {e}")
        return jsonify({"error": str(e), "like_count": 0}), 500

@app.route("/comment", methods=["POST"])
def comment():
    text = request.form["comment"]
    if text.strip():
        try:
            new_comment = Comment(text=text)
            db.session.add(new_comment)
            db.session.commit()
            return jsonify({"comment": {"text": new_comment.text, "timestamp": new_comment.timestamp.isoformat()}})
        except Exception as e:
            print(f"Error in comment route: {e}")
            return jsonify({"error": str(e)}), 500
    return jsonify({"error": "Comment cannot be empty"}), 400

@app.route("/debug")
def debug():
    try:
        likes_count = Like.query.count()
        comments = Comment.query.order_by(Comment.timestamp.desc()).all()
        comments_data = [{"id": c.id, "text": c.text, "timestamp": c.timestamp.strftime("%Y-%m-%d %H:%M:%S")} for c in comments]

        # Add connection info for debugging
        connection_info = {
            "db_host": db_host,
            "db_port": db_port,
            "db_name": db_name,
            "db_user": db_user
        }

        return jsonify({
            "like_count": likes_count,
            "comments": comments_data,
            "connection_info": connection_info
        })
    except Exception as e:
        return jsonify({"error": str(e), "status": "database error"}), 500

@app.route("/monitor")
def monitor():
    try:
        likes_count = Like.query.count()
        comments = Comment.query.order_by(Comment.timestamp.desc()).all()
        
        # Create a simpler version without time-based filtering since Like may not have timestamp
        # Get just comment statistics by day (since Comment has timestamp)
        thirty_days_ago = datetime.now() - timedelta(days=30)
        
        # Group comments by day
        daily_comments = db.session.query(
            func.date(Comment.timestamp).label('date'),
            func.count(Comment.id).label('count')
        ).filter(Comment.timestamp >= thirty_days_ago).group_by(func.date(Comment.timestamp)).all()
        
        # Convert to dictionaries for easier template rendering
        daily_comments_dict = {str(day.date): day.count for day in daily_comments}
        
        # Generate date labels for the last 30 days
        date_labels = [(datetime.now() - timedelta(days=i)).strftime('%Y-%m-%d') for i in range(30, -1, -1)]
        
        # Get data for each day (0 if no data for that day)
        comments_data = [daily_comments_dict.get(date, 0) for date in date_labels]
        
        return render_template(
            "monitor.html", 
            like_count=likes_count, 
            comments=comments,
            date_labels=date_labels,
            comments_data=comments_data
        )
    except Exception as e:
        print(f"Error in monitor route: {e}")
        return render_template("monitor.html", error=str(e), like_count=0, comments=[])

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)