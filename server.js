import express from "express";
import cors from "cors";
import bcrypt from "bcryptjs";
import pool from "./db.js"
import jwt from "jsonwebtoken";
import env from "dotenv";
import axios from "axios";
import http from "http"; 
import https from 'https';
import { Server } from "socket.io";  
import fs from 'fs';
import session from "express-session";
import Sequelize from "sequelize";
import SequelizeStoreInit from "connect-session-sequelize";

const app = express();
app.use(express.json()); 

app.use(cors({
    origin: "*", 
    credentials: true, 
    methods: "GET,HEAD,PUT,PATCH,POST,DELETE",
    allowedHeaders: "Content-Type, Authorization"
}));

env.config();

const YEAR_TO_MILLISECOND_CONVERTION_FACTOR = 365 * 24 * 60 * 60 * 1000;

const privateKey = fs.readFileSync('private.key', 'utf8');
const certificate = fs.readFileSync('certificate.crt', 'utf8');
const credentials = { key: privateKey, cert: certificate };

const server = http.createServer(credentials, app);

const io = new Server(server);

let clients = []; 

io.on("connection", (socket) => {
    console.log("A new client connected:", socket.id);
    clients.push(socket);

    socket.on('message', (msg) => {
        console.log('Received message:', msg);
    });


    socket.on("disconnect", () => {
        console.log("A client disconnected:", socket.id);
        clients = clients.filter(client => client !== socket);
    });

    socket.on("location-update", (data) => {
        // Broadcast location update to all connected clients (or to a specific room)
        io.emit("location-update", data);
    });

    // socket.join(rideId); // when a ride starts
    // io.to(rideId).emit("location-update", data);

    // In the driver’s app (if using JavaScript, similar for iOS)
    socket.emit("location-update", {
        userId: driverId, // if needed
        latitude: currentLatitude,
        longitude: currentLongitude
    });



    io.emit('anotherEvent', { message: 'Hello from server!' });
});
  
// JWT Authentication Middleware
const authMiddleware = (req, res, next) => {
    const token = req.headers.authorization?.split(' ')[1]; // Get token from Authorization header

    if (!token) {
        return res.status(401).json({ error: "Unauthorized" });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET); // Verify token using the secret
        req.user = decoded; // Attach user data to the request object
        next();
    } catch (err) {
        return res.status(401).json({ error: "Invalid or expired token" });
    }
};

app.get('/', (req, res) => {
    res.send('Hello, Backend!');
});

app.post("/signup", async (req, res) => {
    const { fullName, email, username, password, role, latitude, longitude } = req.body;
  
    if (!fullName || !email || !username || !password || !role || latitude === undefined || longitude === undefined) {
      return res.status(400).json({ error: "All fields are required" });
    }
  
    try {
      const userCheck = await pool.query("SELECT * FROM users WHERE email = $1 OR username = $2", [email, username]);
      if (userCheck.rows.length > 0) {
        return res.status(400).json({ error: "Email or username already exists" });
      }

      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(password, salt);
  
      const newUserResult = await pool.query(
        "INSERT INTO users (full_name, email, username, password, role, latitude, longitude, created_at) VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_TIMESTAMP) RETURNING *",
        [fullName, email, username, hashedPassword, role, latitude, longitude]
      );

      const newUser = newUserResult.rows[0];


      const token = jwt.sign(
        { userId: newUser.id, username: newUser.username, email: newUser.email }, 
        process.env.JWT_SECRET, 
        { expiresIn: '1h' } 
      );
      console.log("token", token)
  
      res.status(201).json({ message: "User registered successfully", token });
    } catch (error) {
      console.error("Error signing up:", error);
      res.status(500).json({ error: "Internal server error" });
    }
});

app.post("/login", async (req, res) => {
    const { username, password, latitude, longitude } = req.body;
  
    try {
      const result = await pool.query(
        "SELECT id, password, email FROM users WHERE username = $1",
        [username]
      );
  
      if (result.rows.length === 0) {
        return res.status(401).json({ error: "Invalid username or password" });
      }
  
      const user = result.rows[0];
      const isMatch = await bcrypt.compare(password, user.password);
  
      if (!isMatch) {
        return res.status(401).json({ error: "Invalid username or password" });
      }

      await pool.query(
        "UPDATE users SET latitude = $1, longitude = $2 WHERE id = $3",
        [latitude, longitude, user.id]
      );

      const token = jwt.sign(
        { userId: user.id, username, email: user.email }, 
        process.env.JWT_SECRET, 
        { expiresIn: '1h' } 
      );
      console.log("token", token)

      res.json({ message: 'Login successful', token, userId: user.id, email: user.email });
    } catch (error) {
      console.error("Login error:", error);
      res.status(500).json({ error: "Server error" });
    }
});

app.get("/user-role", authMiddleware, async (req, res) => {
    const userId = req.user.userId;

    try {
        const result = await pool.query(
            'SELECT role FROM users WHERE id = $1',
            [userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.json({ role: result.rows[0].role });
    } catch (err) {
        console.error('Error fetching user role:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});


app.post('/update-location', async (req, res) => {
    const { email, latitude, longitude } = req.body;
  
    if (!email || latitude == null || longitude == null) {
      return res.status(400).json({ error: 'Missing fields' });
    }
  
    try {
        const result = await pool.query(
            `UPDATE users 
              SET latitude = $1, longitude = $2 
              WHERE email = $3
              RETURNING *;`,
            [latitude, longitude, email] 
        );
      

        if (result.rows.length > 0) {
            const updatedUser = result.rows[0];
    
            const locationUpdate = {
            userId: updatedUser.email,
            latitude: updatedUser.latitude,
            longitude: updatedUser.longitude
            };
            
            io.emit("location-update", locationUpdate);
            
  
            res.json({ message: 'Location updated successfully' });
        } else {
            res.status(404).json({ error: 'User not found' });
        }
    } catch (err) {
      console.error('Location update error:', err);
      res.status(500).json({ error: 'Database error' });
    }
});


// get current user signed in
app.get('/profile', authMiddleware, async (req, res) => {
    const userId = req.user.userId;
  
    try {
      const result = await pool.query(
        'SELECT id, full_name, email, username, role, latitude, longitude FROM users WHERE id = $1',
        [userId]
      );
      
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
  
      res.json({ profile: result.rows[0] });
    } catch (err) {
      console.error('Error fetching profile:', err);
      res.status(500).json({ error: 'Internal server error' });
    }
});

//get a particular user using their id
app.get('/profile/:id', async (req, res) => {
    const userId = req.params.id;
    try {
      const result = await pool.query(
        'SELECT id, full_name, email, username, role, latitude, longitude FROM users WHERE id = $1',
        [userId]
      );
      
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
  
      res.json({ profile: result.rows[0] });
    } catch (err) {
      console.error('Error fetching profile by id:', err);
      res.status(500).json({ error: 'Internal server error' });
    }
});
  
  
app.get("/locations", async (req, res) => {
    const {email} =  req.query;

    if (!email) {
        return res.status(400).json({ error: "Email is required" });
    }
    try {
        const query = "SELECT * FROM users WHERE email = $1";
        const result = await pool.query(query, [email]);

        if (result.rows.length > 0) {
            res.json(result.rows[0]);
        } else {
            res.status(404).json({ error: `${role.charAt(0).toUpperCase() + role.slice(1)} not found` });
        }
    } catch (error) {
        console.error("Error fetching locations:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

app.get("/directions", async (req, res) => {
    const { origin, destination } = req.query;
    const API_KEY = process.env.GOOGLE_MAPS_API_KEY;
  
    try {
      const response = await axios.get(
        `https://maps.googleapis.com/maps/api/directions/json?origin=${origin}&destination=${destination}&mode=driving&departure_time=now&key=${API_KEY}`
      );
  
      res.json(response.data);
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
});

app.post("/drivers", async (req, res) => {
    const { name, car_model, license_plate, car_color, inbound_hours, outbound_hours, num_rides } = req.body;
    
    if (!name || !car_model || !license_plate || !car_color || !inbound_hours || !outbound_hours) {
        return res.status(400).json({ error: "All fields except number of rides are required" });
    }
    
    try {
        const result = await pool.query(
            `INSERT INTO StudentDriver (name, car_model, license_plate, car_color, inbound_hours, outbound_hours, num_rides)
             VALUES ($1, $2, $3, $4, $5, $6, $7)
             RETURNING *`,
            [name, car_model, license_plate, car_color, inbound_hours, outbound_hours, num_rides || 0]
        );
        res.status(201).json({ message: "Driver profile created", driver: result.rows[0] });
    } catch (error) {
        console.error("Error creating driver profile:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

app.get("/drivers", async (req, res) => {
    const { route } = req.query; 
    
    try {
        let query = "SELECT * FROM StudentDriver";
        let params = [];
        
        if (route && (route === "inbound" || route === "outbound")) {
        }
        
        const result = await pool.query(query, params);
        res.json(result.rows);
    } catch (error) {
        console.error("Error fetching drivers:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

app.get("/drivers/:id", async (req, res) => {
    const driverId = req.params.id;
    try {
        const result = await pool.query("SELECT * FROM StudentDriver WHERE id = $1", [driverId]);
        if (result.rows.length === 0) {
            return res.status(404).json({ error: "Driver not found" });
        }
        res.json(result.rows[0]);
    } catch (error) {
        console.error("Error fetching driver profile:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

app.put("/drivers/:id", async (req, res) => {
    const driverId = req.params.id;
    const { name, car_model, license_plate, car_color, inbound_hours, outbound_hours, num_rides } = req.body;
    
    try {
        const result = await pool.query(
            `UPDATE StudentDriver 
             SET name = $1, car_model = $2, license_plate = $3, car_color = $4, inbound_hours = $5, outbound_hours = $6, num_rides = $7
             WHERE id = $8
             RETURNING *`,
            [name, car_model, license_plate, car_color, inbound_hours, outbound_hours, num_rides, driverId]
        );
        
        if (result.rows.length === 0) {
            return res.status(404).json({ error: "Driver not found" });
        }
        
        res.json({ message: "Driver profile updated", driver: result.rows[0] });
    } catch (error) {
        console.error("Error updating driver profile:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});




app.post("/request-ride", authMiddleware, async (req, res) => {
    const { rideType } = req.body;  
    const userId = req.user.userId;

    if (!rideType || (rideType !== "inbound" && rideType !== "outbound")) {
        return res.status(400).json({ error: "Invalid ride type" });
    }
    
    try {
        const newRide = await pool.query(
            "INSERT INTO rides (user_id, ride_type, status) VALUES ($1, $2, 'pending') RETURNING *",
            [userId, rideType]
        );
        io.emit("ride-request", newRide.rows[0]);
        res.status(201).json({ message: "Ride requested", ride: newRide.rows[0] });
    } catch (error) {
        console.error("Ride request error:", error);
        res.status(500).json({ error: "Internal server error" });
    }

})

app.get("/pending-rides", authMiddleware, async (req, res) => {
    try {
        const result = await pool.query("SELECT * FROM rides WHERE status = 'pending'");
        res.json(result.rows);
    } catch (error) {
        console.error("Error fetching pending rides:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});


app.post("/book-ride", authMiddleware, async (req, res) => {
    const { pickup, destination } = req.body;
    const userId = req.user.userId;
    
    try {
        const newRide = await pool.query(
            "INSERT INTO rides (user_id, pickup, destination, status) VALUES ($1, $2, $3, 'pending') RETURNING *",
            [userId, pickup, destination]
        );
        io.emit("ride-booked", newRide.rows[0]);  // Emit event
        res.status(201).json({ message: "Ride booked", ride: newRide.rows[0] });
    } catch (error) {
        console.error("Ride booking error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

app.post("/book-ride", authMiddleware, async (req, res) => {
    const { pickup, destination } = req.body;
    const userId = req.user.userId;
    
    try {
        const newRide = await pool.query(
            "INSERT INTO rides (user_id, pickup, destination, status) VALUES ($1, $2, $3, 'pending') RETURNING *",
            [userId, pickup, destination]
        );
        io.emit("ride-booked", newRide.rows[0]); 
        res.status(201).json({ message: "Ride booked", ride: newRide.rows[0] });
    } catch (error) {
        console.error("Ride booking error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

app.post("/send-ride-notification", (req, res) => {
    const { message } = req.body;
    io.emit("ride-notification", { message });
    res.json({ message: "Notification sent" });
});



app.post("/accept-ride", async (req, res) => {
    const { rideId } = req.body;
    const driverId = req.user.userId;
    try {
        const updatedRide = await pool.query(
            "UPDATE rides SET driver_id = $1, status = 'accepted' WHERE id = $2 RETURNING *",
            [driverId, rideId]
        );
        io.emit("ride-accepted", updatedRide.rows[0]);
        res.json({ message: "Ride accepted", ride: updatedRide.rows[0] });
    } catch (error) {
        console.error("Ride accept error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
    
})

app.post("/complete-ride", authMiddleware, async (req, res) => {
    const { rideId } = req.body;
    try {
        const updatedRide = await pool.query(
            "UPDATE rides SET status = 'completed' WHERE id = $1 RETURNING *",
            [rideId]
        );
        io.emit("ride-completed", updatedRide.rows[0]);
        res.json({ message: "Ride completed", ride: updatedRide.rows[0] });
    } catch (error) {
        console.error("Ride completion error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
    
})

app.get("/active-rides", authMiddleware, async (req, res) => {
    const userId = req.user.userId;
    try {
        const activeRides = await pool.query(
            "SELECT * FROM rides WHERE (user_id = $1 OR driver_id = $1) AND status IN ('pending', 'accepted')",
            [userId]
        );
        res.json(activeRides.rows);
    } catch (error) {
        console.error("Error fetching rides:", error);
        res.status(500).json({ error: "Internal server error" });
    }
})

const getMealTime = () => {
    const now = new Date();
    const hours = now.getHours();
    const day = now.toLocaleString('en-US', { weekday: 'long' });
  
    let mealTime = '';
  
    if (day === 'Saturday' || day === 'Sunday') {
   
      mealTime = hours < 16 ? 'Brunch' : 'Dinner';
    } else {
     
      if (hours < 11) {
        mealTime = 'Breakfast';
      } else if (hours < 16) {
        mealTime = 'Lunch';
      } else {
        mealTime = 'Dinner';
      }
    }
  
    return { day, mealTime };
};

app.get('/meals', async (req, res) => {
    try {
      const { day, mealTime } = getMealTime();
      
      // Fetch meals based on current day and time slot
      const result = await pool.query(
        'SELECT * FROM menuitem WHERE day = $1 AND meal_time = $2',
        [day, mealTime]
      );
  
      res.json(result.rows);
    } catch (err) {
      console.error(err);
      res.status(500).send('Server Error');
    }
});
  
const PORT = 3000;
server.listen(PORT, () => {
    console.log(`Server running on port: ${PORT}`);
});