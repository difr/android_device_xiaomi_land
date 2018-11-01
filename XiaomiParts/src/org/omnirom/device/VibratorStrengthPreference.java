/*
* Copyright (C) 2016 The OmniROM Project
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 2 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program. If not, see <http://www.gnu.org/licenses/>.
*
*/
package org.omnirom.device;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Vibrator;
import android.support.v7.preference.PreferenceManager;
import android.util.AttributeSet;

public class VibratorStrengthPreference extends ProperSeekBarPreference {

    // from drivers/platform/msm/qpnp-haptic.c
    // #define QPNP_HAP_VMAX_MIN_MV		116
    // #define QPNP_HAP_VMAX_MAX_MV		3596
    private static int mMinVal = 116;
    private static int mMaxVal = 3596;
    private static int mDefVal = mMaxVal - (mMaxVal - mMinVal) / 4;

    private static final String KEY = DeviceSettings.KEY_VIBSTRENGTH;
    private static final String FILE = "/sys/class/timed_output/vibrator/vtg_level";
    private static final long testVibrationPattern[] = {0,250};

    public VibratorStrengthPreference(Context context, AttributeSet attrs) {
        super(context, attrs);

        mInterval = 10;
        mShowSign = false;
        mUnits = "";
        mContinuousUpdates = false;
        mMinValue = mMinVal;
        mMaxValue = mMaxVal;
        mDefaultValueExists = true;
        mDefaultValue = mDefVal;
        if (isSupported(context))
            mValue = Integer.parseInt(readValue(context));
        setPersistent(false);
    }

    public static boolean isSupported(Context context) {
        return Utils.fileWritable(FILE);
    }

    public static void restore(Context context) {
        SharedPreferences sharedPrefs = PreferenceManager.getDefaultSharedPreferences(context);
        if (sharedPrefs.contains(KEY))
            writeValue(context, sharedPrefs.getString(KEY, String.valueOf(mDefVal)));
    }

    public static String readValue(Context context) {
        return Utils.readValue(FILE, String.valueOf(mDefVal));
    }

    public static void writeValue(Context context, String newValue) {
        Utils.writeValue(FILE, newValue);
    }

    public static void saveValue(Context context, String newValue) {
        writeValue(context, newValue);
        SharedPreferences.Editor editor = PreferenceManager.getDefaultSharedPreferences(context).edit();
        editor.putString(KEY, newValue);
        editor.commit();
    }

    @Override
    protected void changeValue(int newValue) {
        saveValue(getContext(), String.valueOf(newValue));
        ((Vibrator) getContext().getSystemService(Context.VIBRATOR_SERVICE)).vibrate(testVibrationPattern, -1);
    }
}
