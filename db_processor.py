import sqlite3

# Establish a connection to the database
conn = sqlite3.connect('steganography.db')
c = conn.cursor()

# Create the messages table if it doesn't exist
c.execute('''CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    sender_id TEXT,
    recipient_id TEXT,
    message_type TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users (id),
    FOREIGN KEY (recipient_id) REFERENCES users (id)
)''')
conn.commit()

# Close the connection
conn.close()