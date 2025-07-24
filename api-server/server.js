const express = require('express');
const cors = require('cors');
const fs = require('fs-extra');
const path = require('path');
const { fromPath } = require('pdf2pic');
const sharp = require('sharp');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// PDF storage directory
const PDF_DIR = path.join(__dirname, 'pdfs');
const THUMBNAIL_DIR = path.join(__dirname, 'thumbnails');

// Ensure thumbnail directory exists
fs.ensureDirSync(THUMBNAIL_DIR);

// Mock PDF metadata database
const pdfDatabase = [
  {
    id: 'cologne-2025-07-23',
    title: 'Köln Rechtsrheinisch',
    description: 'E-Paper vom 23.07.2025',
    publishDate: '2025-07-23T00:00:00.000Z',
    thumbnailUrl: null,
    fileSize: 2048576,
    pageCount: 36,
    tags: ['Köln', 'Rechtsrheinisch', '2025'],
    downloadUrl: `http://localhost:${PORT}/api/pdfs/cologne-2025-07-23/download`,
    metadata: {
      author: 'E-Paper System',
      creationDate: '2025-07-23T08:00:00.000Z',
      version: '1.0'
    },
    filename: '23-07-2025-Koeln-Rechtsrheinisch.pdf'
  },
  {
    id: 'cologne-general',
    title: 'Köln Allgemein',
    description: 'Allgemeine Ausgabe Köln',
    publishDate: '2025-07-20T00:00:00.000Z',
    thumbnailUrl: null,
    fileSize: 1843200,
    pageCount: 36,
    tags: ['Köln', 'Allgemein', '2025'],
    downloadUrl: `http://localhost:${PORT}/api/pdfs/cologne-general/download`,
    metadata: {
      author: 'E-Paper System',
      creationDate: '2025-07-20T08:00:00.000Z',
      version: '1.0'
    },
    filename: 'cologne.pdf'
  }
];

// Helper function to get PDF file path
function getPdfFilePath(pdfId) {
  const pdf = pdfDatabase.find(p => p.id === pdfId);
  if (!pdf) return null;
  return path.join(PDF_DIR, pdf.filename);
}

// Helper function to get file size
async function getFileSize(filePath) {
  try {
    const stats = await fs.stat(filePath);
    return stats.size;
  } catch (error) {
    return 0;
  }
}

// Helper function to generate PDF thumbnail
async function generatePdfThumbnail(pdfId, pdfPath) {
  const thumbnailPath = path.join(THUMBNAIL_DIR, `${pdfId}.png`);
  
  // Check if thumbnail already exists and is newer than PDF
  try {
    const thumbnailStats = await fs.stat(thumbnailPath);
    const pdfStats = await fs.stat(pdfPath);
    
    if (thumbnailStats.mtime > pdfStats.mtime) {
      console.log(`📋 Using cached thumbnail for: ${pdfId}`);
      return thumbnailPath;
    }
  } catch (error) {
    // Thumbnail doesn't exist, will generate new one
  }

  console.log(`🔄 Generating new thumbnail for: ${pdfId}`);
  
  try {
    // Configure pdf2pic options
    const options = {
      density: 100,           // Output resolution
      saveFilename: pdfId,    // Output filename
      savePath: THUMBNAIL_DIR, // Output directory
      format: "png",          // Output format
      width: 400,             // Output width
      height: 600             // Output height
    };

    // Convert first page of PDF to image using pdf2pic
    const convert = fromPath(pdfPath, options);
    const result = await convert(1, { responseType: "image" }); // Convert page 1
    
    // pdf2pic returns the result with the full path
    if (result && result.path) {
      // Move the generated file to our expected location
      const generatedPath = result.path;
      if (await fs.pathExists(generatedPath) && generatedPath !== thumbnailPath) {
        await fs.move(generatedPath, thumbnailPath, { overwrite: true });
      }
    }
    
    // Optimize the image with Sharp if it exists
    if (await fs.pathExists(thumbnailPath)) {
      await sharp(thumbnailPath)
        .resize(400, 600, { 
          fit: 'inside',
          withoutEnlargement: true,
          background: { r: 255, g: 255, b: 255, alpha: 1 }
        })
        .png({ quality: 90 })
        .toFile(thumbnailPath + '.optimized');
      
      // Replace original with optimized version
      await fs.move(thumbnailPath + '.optimized', thumbnailPath, { overwrite: true });
    }
    
    console.log(`✅ Generated thumbnail: ${thumbnailPath}`);
    return thumbnailPath;
    
  } catch (error) {
    console.error(`❌ Error generating thumbnail for ${pdfId}:`, error);
    throw error;
  }
}

// Routes

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    service: 'E-Paper API Server'
  });
});

// Get list of available PDFs
app.get('/api/pdfs', async (req, res) => {
  try {
    console.log('📋 GET /api/pdfs - Fetching PDF list');
    
    // Update file sizes from actual files
    const updatedPdfs = await Promise.all(
      pdfDatabase.map(async (pdf) => {
        const filePath = getPdfFilePath(pdf.id);
        if (filePath && await fs.pathExists(filePath)) {
          const actualSize = await getFileSize(filePath);
          return { ...pdf, fileSize: actualSize };
        }
        return pdf;
      })
    );

    console.log(`✅ Returning ${updatedPdfs.length} PDFs`);
    res.json(updatedPdfs);
  } catch (error) {
    console.error('❌ Error fetching PDF list:', error);
    res.status(500).json({ 
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to fetch PDF list',
        details: error.message
      }
    });
  }
});

// Download PDF file
app.get('/api/pdfs/:id/download', async (req, res) => {
  try {
    const { id } = req.params;
    console.log(`📥 GET /api/pdfs/${id}/download - Downloading PDF`);
    
    const filePath = getPdfFilePath(id);
    if (!filePath) {
      console.log(`❌ PDF not found: ${id}`);
      return res.status(404).json({
        error: {
          code: 'PDF_NOT_FOUND',
          message: 'The requested PDF document was not found',
          details: `No PDF with ID '${id}' exists`
        }
      });
    }

    // Check if file exists
    if (!await fs.pathExists(filePath)) {
      console.log(`❌ PDF file not found on disk: ${filePath}`);
      return res.status(404).json({
        error: {
          code: 'FILE_NOT_FOUND',
          message: 'PDF file not found on server',
          details: `File does not exist: ${path.basename(filePath)}`
        }
      });
    }

    // Get file stats
    const stats = await fs.stat(filePath);
    const pdf = pdfDatabase.find(p => p.id === id);

    // Set appropriate headers
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Length', stats.size);
    res.setHeader('Content-Disposition', `inline; filename="${pdf?.filename || 'document.pdf'}"`);
    res.setHeader('Cache-Control', 'public, max-age=86400'); // 24 hours

    console.log(`✅ Serving PDF: ${path.basename(filePath)} (${stats.size} bytes)`);

    // Stream the file
    const fileStream = fs.createReadStream(filePath);
    fileStream.pipe(res);

    fileStream.on('error', (error) => {
      console.error('❌ Error streaming PDF:', error);
      if (!res.headersSent) {
        res.status(500).json({
          error: {
            code: 'STREAM_ERROR',
            message: 'Error streaming PDF file',
            details: error.message
          }
        });
      }
    });

  } catch (error) {
    console.error('❌ Error downloading PDF:', error);
    res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to download PDF',
        details: error.message
      }
    });
  }
});

// Get PDF metadata
app.get('/api/pdfs/:id/metadata', (req, res) => {
  try {
    const { id } = req.params;
    console.log(`📊 GET /api/pdfs/${id}/metadata - Fetching metadata`);
    
    const pdf = pdfDatabase.find(p => p.id === id);
    if (!pdf) {
      console.log(`❌ PDF not found: ${id}`);
      return res.status(404).json({
        error: {
          code: 'PDF_NOT_FOUND',
          message: 'The requested PDF document was not found',
          details: `No PDF with ID '${id}' exists`
        }
      });
    }

    const metadata = {
      id: pdf.id,
      title: pdf.title,
      author: pdf.metadata.author,
      creationDate: pdf.metadata.creationDate,
      pageCount: pdf.pageCount,
      fileSize: pdf.fileSize,
      version: pdf.metadata.version,
      keywords: pdf.tags,
      subject: pdf.description,
      producer: 'E-Paper Publishing System',
      creator: 'E-Paper System'
    };

    console.log(`✅ Returning metadata for: ${pdf.title}`);
    res.json(metadata);
  } catch (error) {
    console.error('❌ Error fetching metadata:', error);
    res.status(500).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to fetch PDF metadata',
        details: error.message
      }
    });
  }
});

// Get PDF thumbnail
app.get('/api/pdfs/:id/thumbnail', async (req, res) => {
  try {
    const { id } = req.params;
    console.log(`🖼️ GET /api/pdfs/${id}/thumbnail - Generating PDF thumbnail`);
    
    const pdfPath = getPdfFilePath(id);
    if (!pdfPath) {
      console.log(`❌ PDF not found: ${id}`);
      return res.status(404).json({
        error: {
          code: 'PDF_NOT_FOUND',
          message: 'The requested PDF document was not found',
          details: `No PDF with ID '${id}' exists`
        }
      });
    }

    // Check if PDF file exists
    if (!await fs.pathExists(pdfPath)) {
      console.log(`❌ PDF file not found on disk: ${pdfPath}`);
      return res.status(404).json({
        error: {
          code: 'FILE_NOT_FOUND',
          message: 'PDF file not found on server',
          details: `File does not exist: ${path.basename(pdfPath)}`
        }
      });
    }

    // Generate PDF thumbnail from first page
    const thumbnailPath = await generatePdfThumbnail(id, pdfPath);
    
    // Check if thumbnail was generated successfully
    if (!await fs.pathExists(thumbnailPath)) {
      console.log(`❌ Failed to generate thumbnail: ${thumbnailPath}`);
      return res.status(500).json({
        error: {
          code: 'THUMBNAIL_GENERATION_FAILED',
          message: 'Failed to generate PDF thumbnail',
          details: 'Thumbnail file was not created'
        }
      });
    }

    // Get thumbnail file stats
    const stats = await fs.stat(thumbnailPath);
    
    // Set appropriate headers
    res.setHeader('Content-Type', 'image/png');
    res.setHeader('Content-Length', stats.size);
    res.setHeader('Cache-Control', 'public, max-age=604800'); // 7 days
    res.setHeader('ETag', `"${id}-${stats.mtime.getTime()}"`);

    console.log(`✅ Serving PDF thumbnail for: ${id} (${stats.size} bytes)`);

    // Stream the thumbnail file
    const thumbnailStream = fs.createReadStream(thumbnailPath);
    thumbnailStream.pipe(res);

    thumbnailStream.on('error', (error) => {
      console.error('❌ Error streaming thumbnail:', error);
      if (!res.headersSent) {
        res.status(500).json({
          error: {
            code: 'STREAM_ERROR',
            message: 'Error streaming thumbnail file',
            details: error.message
          }
        });
      }
    });

  } catch (error) {
    console.error('❌ Error generating thumbnail:', error);
    res.status(500).json({
      error: {
        code: 'THUMBNAIL_GENERATION_ERROR',
        message: 'Failed to generate PDF thumbnail',
        details: error.message
      }
    });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('❌ Unhandled error:', error);
  res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'Internal server error',
      details: error.message
    }
  });
});

// 404 handler
app.use((req, res) => {
  console.log(`❌ 404 - Route not found: ${req.method} ${req.path}`);
  res.status(404).json({
    error: {
      code: 'ROUTE_NOT_FOUND',
      message: 'API endpoint not found',
      details: `${req.method} ${req.path} is not a valid endpoint`
    }
  });
});

// Start server
app.listen(PORT, () => {
  console.log('🚀 E-Paper API Server started');
  console.log(`📡 Server running on http://localhost:${PORT}`);
  console.log(`📋 API endpoints:`);
  console.log(`   GET  /health                     - Health check`);
  console.log(`   GET  /api/pdfs                   - List PDFs`);
  console.log(`   GET  /api/pdfs/:id/download      - Download PDF`);
  console.log(`   GET  /api/pdfs/:id/metadata      - Get metadata`);
  console.log(`   GET  /api/pdfs/:id/thumbnail     - Get thumbnail (PNG)`);
  console.log('');
  console.log(`📁 PDF directory: ${PDF_DIR}`);
  console.log(`📊 Available PDFs: ${pdfDatabase.length}`);
  
  // Check if PDF files exist
  pdfDatabase.forEach(async (pdf) => {
    const filePath = getPdfFilePath(pdf.id);
    if (filePath && await fs.pathExists(filePath)) {
      console.log(`   ✅ ${pdf.filename} (${pdf.title})`);
    } else {
      console.log(`   ❌ ${pdf.filename} (${pdf.title}) - FILE NOT FOUND`);
    }
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('🛑 SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('🛑 SIGINT received, shutting down gracefully');
  process.exit(0);
});
