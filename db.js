import pg from "pg";
import env from "dotenv";

env.config();

const { Pool } = pg;

const pool = new Pool({
    connectionString: process.env.DB_URL,
    ssl: {rejectUnauthorized: false,}, 
});

console.log('DB_URL:', process.env.DB_URL);



pool.connect()
    .then(() => {
        console.log("Connected to the database successfully!");
    })
    .catch(err => {
        console.error("Error connecting to the database:", err);
        process.exit(1);  
    });

process.on("SIGINT", async () => {
    await pool.end();
    console.log("Database connection closed.");
    process.exit(0);
});

export default pool;
