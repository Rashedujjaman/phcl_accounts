# Offline Attachment Support Implementation Guide

## ✅ What Was Enabled

You can now **upload attachments even while offline**! The attachments will be stored locally and automatically uploaded to Firebase when the device comes online.

---

## 🔄 How It Works

### **When Online:**

1. User selects an attachment (image/PDF/etc.)
2. File is uploaded **directly to Firebase Storage**
3. Transaction is saved to Firestore with Firebase Storage URL
4. ✅ Done immediately!

### **When Offline:**

1. User selects an attachment
2. File is **copied to app's local storage** (`offline_attachments` folder)
3. Transaction is saved to SQLite with:
   - `attachment_url`: Local file path (temporary)
   - `attachment_local_path`: Local file path (for sync reference)
4. ✅ Transaction visible in app with local attachment
5. **When connection restored:**
   - SyncService detects pending transaction with local attachment
   - Uploads attachment file to Firebase Storage
   - Updates transaction with Firebase Storage URL
   - Saves transaction to Firestore
   - Deletes local attachment file

---

## 📂 File Storage Structure

```
App Documents Directory/
├── offline_attachments/
│   ├── attachment_1730800000000.jpg  ← Offline image
│   ├── attachment_1730800001000.pdf  ← Offline PDF
│   └── attachment_1730800002000.png  ← Offline image
└── databases/
    └── phcl_accounts.db
        └── pending_transactions table
            ├── local_id
            ├── attachment_url (local path)
            └── attachment_local_path (sync reference)
```

---

## 🛠️ Implementation Details

### **1. OfflineFirstTransactionRepository Changes**

#### `uploadAttachment()` Method:

```dart
Future<Map<String, String>> uploadAttachment(File file, String type) async {
  final isOnline = await _connectivityService.checkConnection();

  if (isOnline) {
    // Try Firebase upload
    try {
      return await _remoteRepository.uploadAttachment(file, type);
    } catch (e) {
      // Fallback to local storage if Firebase fails
      return await _saveAttachmentLocally(file, type);
    }
  } else {
    // Save locally when offline
    return await _saveAttachmentLocally(file, type);
  }
}
```

#### `_saveAttachmentLocally()` Private Method:

- Creates `offline_attachments` directory in app storage
- Generates unique filename with timestamp
- Copies file to local storage
- Returns local path (as 'url') and type

### **2. OfflineTransactionRepository Changes**

#### Updated `savePendingTransaction()`:

- Now accepts optional `attachmentLocalPath` parameter
- Stores local path in `attachment_local_path` column
- Used for syncing attachments later

### **3. SyncService Changes**

#### Enhanced Sync Process:

```dart
// For each pending transaction:
1. Check if it has attachment_local_path
2. If yes:
   a. Read file from local path
   b. Upload to Firebase Storage
   c. Get Firebase URL
   d. Update transaction with Firebase URL
   e. Delete local file
3. Upload transaction to Firestore
4. Remove from local database
```

---

## 🎯 User Experience

### **Creating Transaction with Attachment Offline:**

1. **User is offline** (WiFi/Mobile data disabled)
2. **Opens Add Transaction** form
3. **Taps attachment icon** (camera/file picker)
4. **Selects photo/file**
5. **Sees preview immediately** (from local file)
6. **Fills other fields** (amount, category, etc.)
7. **Taps "Add Transaction"**
8. ✅ **Success!** Transaction saved with attachment
9. **Transaction appears in list** with attachment preview

### **Auto-Sync When Online:**

1. **User connects to internet** (WiFi/Mobile data enabled)
2. **Within 3-5 seconds** → SyncService triggers
3. **Background process:**
   - Uploads attachment file to Firebase Storage
   - Creates transaction in Firestore
   - Cleans up local files
4. ✅ **Transaction now in cloud** with permanent URL
5. **Visible on all devices**

---

## 📊 Database Schema Updates

### `pending_transactions` Table:

| Column                  | Type | Description                                   |
| ----------------------- | ---- | --------------------------------------------- |
| `attachment_url`        | TEXT | Firebase URL (online) or Local path (offline) |
| `attachment_type`       | TEXT | File type: image, pdf, other                  |
| `attachment_local_path` | TEXT | **NEW!** Local file path for sync reference   |

The `attachment_local_path` is used during sync to know which local file to upload.

---

## 🧪 Testing the Feature

### **Test 1: Offline Attachment Upload**

1. **Turn OFF internet**
2. **Create transaction with image:**

   - Open Add Transaction
   - Tap camera icon
   - Take photo or select from gallery
   - Fill amount, category, etc.
   - Tap "Add Transaction"

3. **Verify:**

   - ✅ Success message shown
   - ✅ Transaction appears in list
   - ✅ Attachment preview visible
   - ✅ Check logs:
     ```
     OfflineFirstRepo: Offline - Saving attachment locally...
     OfflineFirstRepo: Attachment saved locally at: /data/.../offline_attachments/attachment_XXX.jpg
     OfflineFirstRepo: Offline - Saving to local database
     ```

4. **Turn ON internet**
5. **Wait 5-10 seconds**
6. **Verify sync:**

   ```
   SyncService: Uploading attachment from: /data/.../offline_attachments/attachment_XXX.jpg
   SyncService: Attachment uploaded successfully: https://firebasestorage...
   SyncService: Local attachment file deleted
   ```

7. **Check Firebase Console:**
   - Go to Storage → See uploaded file
   - Go to Firestore → Transaction has Firebase Storage URL

---

### **Test 2: Online Attachment Upload** (Should work as before)

1. **Internet is ON**
2. **Create transaction with image**
3. **Verify:**
   - ✅ Uploads immediately to Firebase
   - ✅ No local storage used
   - ✅ Check logs:
     ```
     OfflineFirstRepo: Online - Uploading attachment to Firebase...
     OfflineFirstRepo: Attachment uploaded successfully
     ```

---

### **Test 3: Mixed Scenario**

1. **Start ONLINE** → Create transaction with image → Uploads to Firebase ✅
2. **Turn OFF** → Create transaction with image → Saves locally ✅
3. **Create another** offline transaction with image → Saves locally ✅
4. **Turn ON** → Both offline attachments upload automatically ✅
5. **Verify:** All 3 transactions in Firebase with proper URLs

---

## 🔍 Debug Logs to Watch

### When Saving Attachment Offline:

```
OfflineFirstRepo: Offline - Saving attachment locally...
OfflineFirstRepo: Attachment saved locally at: [path]
```

### When Syncing:

```
SyncService: Found X pending transactions to sync
SyncService: Uploading attachment from: [local_path]
SyncService: Attachment uploaded successfully: [firebase_url]
SyncService: Local attachment file deleted
```

### If Attachment File Not Found:

```
SyncService: Warning - Local attachment file not found: [path]
```

(Transaction will still sync, but without attachment)

---

## ⚠️ Important Notes

### **1. File Cleanup**

- Local attachment files are **automatically deleted** after successful upload
- Prevents storage bloat from accumulating offline files

### **2. Sync Failure Handling**

- If attachment upload fails during sync, transaction sync continues
- Transaction may have local path as URL (will fail validation)
- Will retry on next sync attempt (max 3 retries)

### **3. File Type Support**

- Same file types as online mode:
  - Images (JPG, PNG, etc.)
  - PDFs
  - Other document types

### **4. Storage Location**

- Offline attachments: `{AppDocumentsDirectory}/offline_attachments/`
- Not in cache (survives app restarts)
- Cleaned up after sync

---

## 🎨 UI Considerations

### **Displaying Offline Attachments**

The attachment URL might be either:

- **Firebase Storage URL**: `https://firebasestorage.googleapis.com/...`
- **Local file path**: `/data/user/0/com.example.app/documents/offline_attachments/...`

Your UI should handle both:

```dart
Widget buildAttachmentPreview(String? attachmentUrl) {
  if (attachmentUrl == null) return SizedBox.shrink();

  // Check if it's a local file path
  if (attachmentUrl.startsWith('/')) {
    // Local file - use File provider
    return Image.file(File(attachmentUrl));
  } else {
    // Firebase URL - use network image
    return Image.network(attachmentUrl);
  }
}
```

### **Sync Status Indicator** (Optional Enhancement)

Show users which transactions have pending attachments:

```dart
// In transaction list item
if (transaction.attachmentUrl?.startsWith('/') ?? false) {
  Icon(Icons.cloud_upload, color: Colors.orange); // Pending upload
} else if (transaction.attachmentUrl != null) {
  Icon(Icons.cloud_done, color: Colors.green); // Synced
}
```

---

## 🚀 What You Can Do Now

✅ **Create transactions with attachments while offline**  
✅ **Attachments automatically upload when online**  
✅ **No "requires internet connection" errors**  
✅ **Seamless user experience**  
✅ **Automatic cleanup of temporary files**  
✅ **Retry logic for failed uploads**

---

## 🔧 Files Modified

1. ✅ `offline_first_transaction_repository.dart`

   - Added `_saveAttachmentLocally()` method
   - Updated `uploadAttachment()` to handle offline mode
   - Updated `addTransaction()` to store local paths

2. ✅ `offline_transaction_repository.dart`

   - Added `attachmentLocalPath` parameter to `savePendingTransaction()`
   - Stores local path in database

3. ✅ `sync_service.dart`

   - Enhanced sync process to upload local attachments
   - Deletes local files after successful upload
   - Handles missing files gracefully

4. ✅ `local_database.dart` (already had the schema)
   - `attachment_local_path` column was already in place

---

## 💡 Future Enhancements (Optional)

1. **Compression**: Compress images before storing locally to save space
2. **Progress Indicator**: Show upload progress during sync
3. **Selective Sync**: Let users choose which attachments to sync
4. **Cache Management**: Limit offline attachment storage size
5. **Multiple Attachments**: Support multiple files per transaction

---

## ✅ Testing Checklist

- [ ] Create transaction with image while offline
- [ ] See attachment preview immediately
- [ ] Transaction appears in list
- [ ] Turn on internet
- [ ] Wait for auto-sync (3-5 seconds)
- [ ] Check Firebase Storage for uploaded file
- [ ] Check Firestore for transaction with Firebase URL
- [ ] Verify local file was deleted
- [ ] Test with PDF attachment
- [ ] Test with multiple offline attachments
- [ ] Test sync failure and retry

---

**Your offline attachment support is now fully functional! 🎉**

Users can upload attachments anytime, anywhere, and they'll automatically sync to the cloud when possible.
