/*
* Copyright (C) 2017 The OmniROM Project
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
import android.support.v7.preference.Preference;
import android.support.v7.preference.Preference.OnPreferenceChangeListener;
import android.support.v7.preference.PreferenceManager;

public class SweepToWakeSwitch implements OnPreferenceChangeListener {

    private static final String KEY = DeviceSettings.KEY_SWEEP2WAKE;
    private static final String FILE = "/sys/android_touch/sweep2wake";

    public static boolean isSupported(Context context) {
        return Utils.fileWritable(FILE);
    }

    public static void restore(Context context) {
        SharedPreferences sharedPrefs = PreferenceManager.getDefaultSharedPreferences(context);
        if (sharedPrefs.contains(KEY))
            writeValue(context, sharedPrefs.getBoolean(KEY, false));
    }

    public static boolean readValue(Context context) {
        return !Utils.readValue(FILE, "0").equals("0");
    }

    public static void writeValue(Context context, boolean newValue) {
        Utils.writeValue(FILE, (newValue ? "1" : "0"));
    }

    @Override
    public boolean onPreferenceChange(Preference preference, Object newValue) {
        writeValue(preference.getContext(), (Boolean) newValue);
        return true;
    }
}
