package dk.wsy;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;
import android.content.Context;
import android.widget.Toast;
import dk.danskebank.mobilepay.sdk.Country;
import dk.danskebank.mobilepay.sdk.MobilePay;
import dk.danskebank.mobilepay.sdk.model.Payment;
import dk.danskebank.mobilepay.sdk.ResultCallback;
import dk.danskebank.mobilepay.sdk.model.FailureResult;
import dk.danskebank.mobilepay.sdk.model.Payment;
import dk.danskebank.mobilepay.sdk.model.SuccessResult;

import android.provider.Settings;
import android.content.Intent;
import android.os.Bundle;
import java.math.BigDecimal;

public class Nta_mobilepay extends CordovaPlugin {
	int MOBILEPAY_PAYMENT_REQUEST_CODE = 1337;
	CallbackContext callback_context = null;
	@Override
	public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
		if ("echo".equals(action)) {
			echo(args.getString(0), callbackContext);
			return true;
		}
		if ("makePayment".equals(action)) {
			if("15".equals(args.getString(2))){
				MobilePay.getInstance().init("APPDK8490224001", Country.DENMARK);
			} else if("16".equals(args.getString(2))){
				MobilePay.getInstance().init("APPDK8749124001", Country.DENMARK);
			} else if("45".equals(args.getString(2))){
				MobilePay.getInstance().init("APPDK2871444001", Country.DENMARK);
			} else if("1".equals(args.getString(2))){
				MobilePay.getInstance().init("APPDK0000000000", Country.DENMARK);
			} else{
				return false;
			}


	// Check if the MobilePay app is installed on the device.
			boolean isMobilePayInstalled = MobilePay.getInstance().isMobilePayInstalled(this.cordova.getActivity().getApplicationContext());

			if (isMobilePayInstalled) {
				// MobilePay is present on the system. Create a Payment object.
				Payment payment = new Payment();
				payment.setProductPrice(new BigDecimal(args.getString(0)));
				payment.setOrderId(args.getString(1));
				//Toast.makeText(webView.getContext(), "ORDRE ID: "+args.getString(1), Toast.LENGTH_SHORT).show();

				// Create a payment Intent using the Payment object from above.
				Intent paymentIntent = MobilePay.getInstance().createPaymentIntent(payment);

				this.callback_context = callbackContext;

				// We now jump to MobilePay to complete the transaction. Start MobilePay and wait for the result using an unique result code of your choice.
				this.cordova.startActivityForResult((CordovaPlugin) this, paymentIntent, this.MOBILEPAY_PAYMENT_REQUEST_CODE);
				return true;
			} else {
				// MobilePay is not installed. Use the SDK to create an Intent to take the user to Google Play and download MobilePay.
				Intent intent = MobilePay.getInstance().createDownloadMobilePayIntent(this.cordova.getActivity().getApplicationContext());
				this.cordova.startActivityForResult((CordovaPlugin) this, intent,0);
			}
		}
		return false;
	}
	@Override
	public void onActivityResult(int requestCode, int resultCode, Intent data) {
	  super.onActivityResult(requestCode, resultCode, data);
		// Toast.makeText(webView.getContext(), "VI BLEV KALDT TILBAGE", Toast.LENGTH_SHORT).show();

	  if (requestCode == this.MOBILEPAY_PAYMENT_REQUEST_CODE) {
		// The request code matches our MobilePay Intent
		MobilePay.getInstance().handleResult(resultCode, data, new ResultCallback() {
		  @Override
		  public void onSuccess(SuccessResult result) {
			//Toast.makeText(webView.getContext(), "Transaktionsid: "+result.getTransactionId() + "Order: "+result.getOrderId(), Toast.LENGTH_LONG).show();
			  webView.loadUrl("file:///android_asset/www/receipt.html?uuid=" +result.getOrderId()+"&transaction_id="+result.getTransactionId()+"&signature="+result.getSignature()+"&java=1");
			// The payment succeeded - you can deliver the product.
		  }
		  @Override
		  public void onFailure(FailureResult result) {
			// The payment failed - show an appropriate error message to the user. Consult the MobilePay class documentation for possible error codes.
		  }
		  @Override
		  public void onCancel() {
			Toast.makeText(webView.getContext(), "Du færdiggjorde ikke din betaling", Toast.LENGTH_LONG).show();
			// The payment was cancelled.
		  }
		});
	  }
	  
	}
	private void echo(String msg, CallbackContext callbackContext) {
		if (msg == null || msg.length() == 0) {
			callbackContext.error("Empty message!");
		} else {
			Toast.makeText(webView.getContext(), msg, Toast.LENGTH_LONG).show();
			callbackContext.success(msg);
		}
	}
}
