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
import android.support.v7.preference.PreferenceManager;
import android.util.AttributeSet;

public class TorchBrightnessPreference extends ProperSeekBarPreference {

    private static int mMinVal = 0;
    private static int mMaxVal = 200;
    private static int mDefVal = mMaxVal;

    private static final String KEY = DeviceSettings.KEY_TORBRIGHTNESS;
    private static final String FILE = "/sys/devices/soc/qpnp-flash-led-23/leds/led:torch_0/max_brightness";

    public TorchBrightnessPreference(Context context, AttributeSet attrs) {
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
    }
}
