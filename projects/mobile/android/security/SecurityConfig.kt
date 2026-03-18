package com.example.security

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.fragment.app.FragmentActivity
import java.io.File
import java.security.KeyStore
import java.security.MessageDigest
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManagerFactory
import javax.net.ssl.X509TrustManager
import okhttp3.CertificatePinner
import okhttp3.OkHttpClient

/**
 * Security Configuration for Android Applications
 */
class SecurityConfig private constructor(private val context: Context) {

    companion object {
        private const val KEYSTORE_PROVIDER = "AndroidKeyStore"
        private const val KEY_ALIAS = "SecurityKey"
        private const val BIOMETRIC_PROMPT_TITLE = "Authentication Required"
        private const val BIOMETRIC_PROMPT_DESCRIPTION = "Verify your identity to continue"

        @Volatile
        private var instance: SecurityConfig? = null

        fun getInstance(context: Context): SecurityConfig =
            instance ?: synchronized(this) {
                instance ?: SecurityConfig(context.applicationContext).also { instance = it }
            }
    }

    // Security Settings
    object SecuritySettings {
        // Root Detection
        const val ENABLE_ROOT_DETECTION = true
        const val ROOT_ACTION = SecurityAction.TERMINATE

        // SSL Pinning
        const val ENABLE_SSL_PINNING = true
        val PINNED_DOMAINS = mapOf(
            "api.example.com" to setOf(
                "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
            ),
            "auth.example.com" to setOf(
                "sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="
            )
        )

        // Encryption
        const val ENABLE_ENCRYPTION = true
        const val KEY_SIZE = 256
        const val BLOCK_MODE = KeyProperties.BLOCK_MODE_GCM
        const val PADDING = KeyProperties.ENCRYPTION_PADDING_NONE

        // Biometric Authentication
        const val ENABLE_BIOMETRICS = true
        const val REQUIRE_STRONG_BIOMETRICS = true

        // Debug Protection
        const val PREVENT_DEBUGGER = true
        const val PREVENT_EMULATOR = true

        // Runtime Integrity
        const val ENABLE_INTEGRITY_CHECKS = true
        const val VERIFY_INSTALLER = true
        const val VERIFY_SIGNATURES = true

        // Network Security
        const val ENFORCE_NETWORK_SECURITY = true
        const val MIN_TLS_VERSION = TlsVersion.TLS_1_2
    }

    enum class SecurityAction {
        TERMINATE,
        WARN,
        BLOCK,
        REPORT
    }

    enum class TlsVersion {
        TLS_1_2,
        TLS_1_3
    }

    // MARK: - Root Detection

    fun checkRoot(): Boolean {
        if (SecuritySettings.ENABLE_ROOT_DETECTION) {
            val rootPaths = arrayOf(
                "/system/app/Superuser.apk",
                "/system/xbin/su",
                "/system/bin/su",
                "/sbin/su",
                "/system/su",
                "/system/bin/.ext/.su"
            )

            // Check for root binaries
            for (path in rootPaths) {
                if (File(path).exists()) {
                    handleSecurityViolation(SecurityViolationType.ROOT_DETECTED)
                    return true
                }
            }

            // Check for root management apps
            val rootApps = arrayOf(
                "com.noshufou.android.su",
                "com.thirdparty.superuser",
                "eu.chainfire.supersu",
                "com.topjohnwu.magisk"
            )

            val packageManager = context.packageManager
            for (app in rootApps) {
                try {
                    packageManager.getPackageInfo(app, 0)
                    handleSecurityViolation(SecurityViolationType.ROOT_DETECTED)
                    return true
                } catch (e: PackageManager.NameNotFoundException) {
                    // Package not found, continue checking
                }
            }

            // Check for test-keys
            val buildTags = Build.TAGS
            if (buildTags != null && buildTags.contains("test-keys")) {
                handleSecurityViolation(SecurityViolationType.ROOT_DETECTED)
                return true
            }
        }
        return false
    }

    // MARK: - SSL Pinning

    fun configureSslPinning(): OkHttpClient {
        val certificatePinner = CertificatePinner.Builder().apply {
            SecuritySettings.PINNED_DOMAINS.forEach { (domain, pins) ->
                pins.forEach { pin ->
                    add(domain, pin)
                }
            }
        }.build()

        return OkHttpClient.Builder()
            .certificatePinner(certificatePinner)
            .apply {
                if (SecuritySettings.MIN_TLS_VERSION == TlsVersion.TLS_1_2) {
                    val trustManagerFactory = TrustManagerFactory.getInstance(
                        TrustManagerFactory.getDefaultAlgorithm()
                    )
                    trustManagerFactory.init(null as KeyStore?)
                    val trustManagers = trustManagerFactory.trustManagers
                    check(!(trustManagers.size != 1 || trustManagers[0] !is X509TrustManager)) {
                        "Unexpected default trust managers: ${trustManagers.contentToString()}"
                    }
                    val trustManager = trustManagers[0] as X509TrustManager

                    val sslContext = SSLContext.getInstance("TLSv1.2")
                    sslContext.init(null, arrayOf(trustManager), null)
                    sslSocketFactory(sslContext.socketFactory, trustManager)
                }
            }
            .build()
    }

    // MARK: - Encryption

    fun configureEncryption() {
        if (SecuritySettings.ENABLE_ENCRYPTION) {
            val keyGenerator = KeyGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_AES,
                KEYSTORE_PROVIDER
            )

            val keyGenSpec = KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setKeySize(SecuritySettings.KEY_SIZE)
                .setBlockModes(SecuritySettings.BLOCK_MODE)
                .setEncryptionPaddings(SecuritySettings.PADDING)
                .setUserAuthenticationRequired(true)
                .setInvalidatedByBiometricEnrollment(true)
                .build()

            keyGenerator.init(keyGenSpec)
            keyGenerator.generateKey()
        }
    }

    // MARK: - Biometric Authentication

    fun configureBiometrics(activity: FragmentActivity, onSuccess: () -> Unit, onError: (String) -> Unit) {
        if (SecuritySettings.ENABLE_BIOMETRICS) {
            val biometricManager = BiometricManager.from(context)
            when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)) {
                BiometricManager.BIOMETRIC_SUCCESS -> {
                    val promptInfo = BiometricPrompt.PromptInfo.Builder()
                        .setTitle(BIOMETRIC_PROMPT_TITLE)
                        .setDescription(BIOMETRIC_PROMPT_DESCRIPTION)
                        .setNegativeButtonText("Cancel")
                        .build()

                    val biometricPrompt = BiometricPrompt(
                        activity,
                        object : BiometricPrompt.AuthenticationCallback() {
                            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                                super.onAuthenticationSucceeded(result)
                                onSuccess()
                            }

                            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                                super.onAuthenticationError(errorCode, errString)
                                onError(errString.toString())
                            }
                        }
                    )

                    biometricPrompt.authenticate(promptInfo)
                }
                else -> onError("Biometric authentication not available")
            }
        }
    }

    // MARK: - Runtime Protection

    fun configureRuntimeProtection() {
        if (SecuritySettings.PREVENT_DEBUGGER && Debug.isDebuggerConnected()) {
            handleSecurityViolation(SecurityViolationType.DEBUGGER_DETECTED)
        }

        if (SecuritySettings.PREVENT_EMULATOR && isEmulator()) {
            handleSecurityViolation(SecurityViolationType.EMULATOR_DETECTED)
        }

        if (SecuritySettings.VERIFY_INSTALLER && !verifyInstaller()) {
            handleSecurityViolation(SecurityViolationType.INVALID_INSTALLER)
        }

        if (SecuritySettings.VERIFY_SIGNATURES && !verifySignatures()) {
            handleSecurityViolation(SecurityViolationType.SIGNATURE_INVALID)
        }
    }

    // MARK: - Helper Methods

    private fun isEmulator(): Boolean {
        return (Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic")
                || Build.FINGERPRINT.startsWith("generic")
                || Build.FINGERPRINT.startsWith("unknown")
                || Build.HARDWARE.contains("goldfish")
                || Build.HARDWARE.contains("ranchu")
                || Build.MODEL.contains("google_sdk")
                || Build.MODEL.contains("Emulator")
                || Build.MODEL.contains("Android SDK built for x86")
                || Build.MANUFACTURER.contains("Genymotion")
                || Build.PRODUCT.contains("sdk_gphone")
                || Build.PRODUCT.contains("google_sdk")
                || Build.PRODUCT.contains("sdk")
                || Build.PRODUCT.contains("sdk_x86")
                || Build.PRODUCT.contains("vbox86p")
                || Build.PRODUCT.contains("emulator")
                || Build.PRODUCT.contains("simulator"))
    }

    private fun verifyInstaller(): Boolean {
        val validInstallers = listOf(
            "com.android.vending",  // Google Play Store
            "com.amazon.venezia"    // Amazon App Store
        )

        val installer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            context.packageManager.getInstallSourceInfo(context.packageName).installingPackageName
        } else {
            @Suppress("DEPRECATION")
            context.packageManager.getInstallerPackageName(context.packageName)
        }

        return installer != null && validInstallers.contains(installer)
    }

    private fun verifySignatures(): Boolean {
        try {
            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                context.packageManager.getPackageInfo(
                    context.packageName,
                    PackageManager.GET_SIGNING_CERTIFICATES
                )
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getPackageInfo(
                    context.packageName,
                    PackageManager.GET_SIGNATURES
                )
            }

            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageInfo.signingInfo.apkContentsSigners
            } else {
                @Suppress("DEPRECATION")
                packageInfo.signatures
            }

            val expectedSignature = "YOUR_EXPECTED_SIGNATURE_HASH"
            val messageDigest = MessageDigest.getInstance("SHA-256")
            
            for (signature in signatures) {
                val signatureBytes = signature.toByteArray()
                val signatureHash = Base64.encodeToString(
                    messageDigest.digest(signatureBytes),
                    Base64.NO_WRAP
                )
                if (signatureHash == expectedSignature) {
                    return true
                }
            }
        } catch (e: Exception) {
            handleSecurityViolation(SecurityViolationType.SIGNATURE_VERIFICATION_ERROR)
        }
        return false
    }

    // MARK: - Security Violation Handling

    enum class SecurityViolationType {
        ROOT_DETECTED,
        DEBUGGER_DETECTED,
        EMULATOR_DETECTED,
        INVALID_INSTALLER,
        SIGNATURE_INVALID,
        SIGNATURE_VERIFICATION_ERROR,
        SSL_PINNING_FAILURE,
        INTEGRITY_VIOLATION
    }

    private fun handleSecurityViolation(type: SecurityViolationType) {
        // Log security violation
        logSecurityViolation(type)

        when (SecuritySettings.ROOT_ACTION) {
            SecurityAction.TERMINATE -> {
                android.os.Process.killProcess(android.os.Process.myPid())
            }
            SecurityAction.WARN -> {
                // Implement warning mechanism
            }
            SecurityAction.BLOCK -> {
                disableAppFunctionality()
            }
            SecurityAction.REPORT -> {
                reportSecurityViolation(type)
            }
        }
    }

    private fun logSecurityViolation(type: SecurityViolationType) {
        // Implement secure logging
    }

    private fun disableAppFunctionality() {
        // Implement app functionality restriction
    }

    private fun reportSecurityViolation(type: SecurityViolationType) {
        // Implement security violation reporting
    }
}
