//const baseUrl = "https://blue.voicejet.app/api";
//const baseUrl = "https://developer.voicejet.app/api";
const baseUrl = "https://voizer.live/api";
const LoginURL = '$baseUrl/login';
const LogOutURL = '$baseUrl/log-out';
const CheckUserStatusURL = '$baseUrl/check-user-status';
const GenerateRoomTokenURL = '$baseUrl/generate-room-token';
const GetUserDataURL = '$baseUrl/get-user-data';
const GetHostJoinedURL = '$baseUrl/get-host-joined-info';
const GetAppVersionURL = '$baseUrl/get-app-version-info';
const UploadUserRecordingURL = '$baseUrl/upload-user-recording';
const UpdateDeviceTokenURL = '$baseUrl/update-device-token';
const GetUserRecordingsURL = '$baseUrl/get-user-recordings';
const ChangePasswordURL = '$baseUrl/change-password';
//new apis
//const LiveKitURL = "https://bluehost-vm78ltfx.livekit.cloud";
const settingsUrl = 'https://voizer.live/app-settings';
const LiveKitURL = "https://bluehost-vm78ltfx.livekit.cloud";
const getRoomIdURL = '$baseUrl/get-user-data/';
const fetchLivekitTokenURL = '$baseUrl/create-token-livekit';
const fetchHostIdentityURL = '$baseUrl/fetch-host-identity';
// 🌍 Global host identity, accessible anywhere
String? globalHostId;