# E-Paper API Specification

This document defines the RESTful API endpoints that the Flutter application expects for loading PDF documents and metadata.

## Base URL

The API base URL is configurable per environment:

- **Development**: `http://localhost:3000`
- **Staging**: `https://api-staging.epaper.example.com`
- **Production**: `https://api.epaper.example.com`

## Authentication

Currently, the API does not require authentication, but this can be added in the future by updating the `Environment.apiHeaders` configuration.

## Endpoints

### 1. Get PDF List

**Endpoint**: `GET /api/pdfs`

**Description**: Returns a list of available PDF documents with metadata.

**Response Format**:
```json
[
  {
    "id": "cologne-2025-07-23",
    "title": "Köln Rechtsrheinisch",
    "description": "E-Paper vom 23.07.2025",
    "publishDate": "2025-07-23T00:00:00.000Z",
    "thumbnailUrl": "https://api.epaper.example.com/api/pdfs/cologne-2025-07-23/thumbnail",
    "fileSize": 2048576,
    "pageCount": 36,
    "tags": ["Köln", "Rechtsrheinisch", "2025"],
    "downloadUrl": "https://api.epaper.example.com/api/pdfs/cologne-2025-07-23/download",
    "metadata": {
      "author": "E-Paper System",
      "creationDate": "2025-07-23T08:00:00.000Z",
      "version": "1.0"
    }
  },
  {
    "id": "cologne-general",
    "title": "Köln Allgemein",
    "description": "Allgemeine Ausgabe Köln",
    "publishDate": "2025-07-20T00:00:00.000Z",
    "thumbnailUrl": "https://api.epaper.example.com/api/pdfs/cologne-general/thumbnail",
    "fileSize": 1843200,
    "pageCount": 36,
    "tags": ["Köln", "Allgemein", "2025"],
    "downloadUrl": "https://api.epaper.example.com/api/pdfs/cologne-general/download",
    "metadata": {
      "author": "E-Paper System",
      "creationDate": "2025-07-20T08:00:00.000Z",
      "version": "1.0"
    }
  }
]
```

**Status Codes**:
- `200 OK`: Success
- `500 Internal Server Error`: Server error

### 2. Download PDF

**Endpoint**: `GET /api/pdfs/{id}/download`

**Description**: Downloads the PDF file content.

**Parameters**:
- `id` (path): The unique identifier of the PDF document

**Response**:
- **Content-Type**: `application/pdf`
- **Body**: Binary PDF data

**Status Codes**:
- `200 OK`: Success
- `404 Not Found`: PDF not found
- `500 Internal Server Error`: Server error

### 3. Get PDF Metadata

**Endpoint**: `GET /api/pdfs/{id}/metadata`

**Description**: Returns detailed metadata for a specific PDF document.

**Parameters**:
- `id` (path): The unique identifier of the PDF document

**Response Format**:
```json
{
  "id": "cologne-2025-07-23",
  "title": "Köln Rechtsrheinisch",
  "author": "E-Paper System",
  "creationDate": "2025-07-23T08:00:00.000Z",
  "pageCount": 36,
  "fileSize": 2048576,
  "version": "1.0",
  "keywords": ["newspaper", "cologne", "local news"],
  "subject": "Local newspaper for Cologne right bank area",
  "producer": "E-Paper Publishing System",
  "creator": "InDesign CC 2024"
}
```

**Status Codes**:
- `200 OK`: Success
- `404 Not Found`: PDF not found
- `500 Internal Server Error`: Server error

### 4. Get PDF Thumbnail (Optional)

**Endpoint**: `GET /api/pdfs/{id}/thumbnail`

**Description**: Returns a thumbnail image of the PDF's first page.

**Parameters**:
- `id` (path): The unique identifier of the PDF document

**Response**:
- **Content-Type**: `image/png` or `image/jpeg`
- **Body**: Binary image data

**Status Codes**:
- `200 OK`: Success
- `404 Not Found`: PDF or thumbnail not found
- `500 Internal Server Error`: Server error

## Data Models

### PdfAsset

```typescript
interface PdfAsset {
  id: string;                    // Unique identifier
  title: string;                 // Display title
  description?: string;          // Optional description
  publishDate: string;           // ISO 8601 date string
  thumbnailUrl?: string;         // Optional thumbnail URL
  fileSize: number;              // File size in bytes
  pageCount: number;             // Number of pages
  tags: string[];                // Array of tags
  downloadUrl?: string;          // Optional direct download URL
  metadata?: Record<string, any>; // Optional additional metadata
}
```

## Error Handling

All endpoints should return appropriate HTTP status codes and error messages:

```json
{
  "error": {
    "code": "PDF_NOT_FOUND",
    "message": "The requested PDF document was not found",
    "details": "No PDF with ID 'invalid-id' exists"
  }
}
```

## CORS Configuration

For web deployments, ensure CORS is properly configured to allow requests from your Flutter web application domains:

```
Access-Control-Allow-Origin: https://your-flutter-app.com
Access-Control-Allow-Methods: GET, OPTIONS
Access-Control-Allow-Headers: Content-Type, Accept
```

## Caching Headers

Implement appropriate caching headers for better performance:

```
Cache-Control: public, max-age=3600  # For PDF list (1 hour)
Cache-Control: public, max-age=86400 # For PDF files (24 hours)
ETag: "unique-version-identifier"
```

## Rate Limiting

Consider implementing rate limiting to prevent abuse:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1627846261
```

## Implementation Notes

1. **File Storage**: PDF files can be stored in cloud storage (AWS S3, Google Cloud Storage) or local filesystem
2. **Database**: Metadata can be stored in any database (PostgreSQL, MongoDB, etc.)
3. **Thumbnails**: Generate thumbnails on upload or on-demand
4. **Security**: Add authentication/authorization as needed
5. **Monitoring**: Implement logging and monitoring for API usage

## Example Implementation

A simple Node.js/Express implementation might look like:

```javascript
app.get('/api/pdfs', async (req, res) => {
  try {
    const pdfs = await getPdfList();
    res.json(pdfs);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/pdfs/:id/download', async (req, res) => {
  try {
    const pdfStream = await getPdfStream(req.params.id);
    res.setHeader('Content-Type', 'application/pdf');
    pdfStream.pipe(res);
  } catch (error) {
    res.status(404).json({ error: 'PDF not found' });
  }
});
```

This API specification ensures that the Flutter application can seamlessly load PDF documents from a RESTful service across all deployment environments.
