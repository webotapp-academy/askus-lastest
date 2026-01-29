# Reviews Feature Deployment Instructions

## Files to Upload to Server

You need to upload these PHP files to your server at `https://indiawebdesigns.in/app/askus/api/reviews/`:

### 1. Create Reviews Directory
First, create a `reviews` folder in your API directory:
```
https://indiawebdesigns.in/app/askus/api/reviews/
```

### 2. Upload PHP Files
Upload these files from your local project to the server:

**Local File** → **Server Location**
- `reviews-list.php` → `https://indiawebdesigns.in/app/askus/api/reviews/list.php`
- `reviews-create.php` → `https://indiawebdesigns.in/app/askus/api/reviews/create.php`
- `reviews-delete.php` → `https://indiawebdesigns.in/app/askus/api/reviews/delete.php`

### 3. File Structure on Server
Your server should have this structure:
```
/app/askus/api/
├── config.php
├── reviews/
│   ├── list.php
│   ├── create.php
│   └── delete.php
└── (other API folders)
```

### 4. Test the Endpoints
After uploading, test these URLs in your browser:
- `https://indiawebdesigns.in/app/askus/api/reviews/list.php?type=product&item_id=1`
- `https://indiawebdesigns.in/app/askus/api/reviews/create.php` (POST request)

## Current Error Analysis
The 404 error occurs because:
- App is trying to POST to: `https://indiawebdesigns.in/app/askus/api/reviews/create.php`
- But the file doesn't exist on the server yet
- The files are only in your local Flutter project directory

## How to Upload Files
Use one of these methods:
1. **FTP/SFTP Client** (FileZilla, WinSCP)
2. **cPanel File Manager**
3. **SSH/Terminal** if you have server access
4. **Your hosting provider's file upload interface**

## Verification Steps
1. Upload the files to the correct server locations
2. Test the API endpoints directly in browser/Postman
3. Run the Flutter app and try submitting a review again

## Important Notes
- Make sure the `config.php` file path is correct in each PHP file
- Ensure proper file permissions (usually 644 for PHP files)
- Check that the `reviews` table exists in your database