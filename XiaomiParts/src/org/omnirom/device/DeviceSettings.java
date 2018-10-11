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

import android.app.AlertDialog;
import android.app.Dialog;
import android.content.res.Resources;
import android.content.Intent;
import android.os.Bundle;
import android.support.v14.preference.PreferenceFragment;
import android.support.v7.preference.ListPreference;
import android.support.v7.preference.Preference;
import android.support.v7.preference.PreferenceCategory;
import android.support.v7.preference.PreferenceScreen;
import android.support.v7.preference.TwoStatePreference;
import android.provider.Settings;
import android.text.TextUtils;
import android.view.MenuItem;
import android.view.View;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ListView;
import android.util.Log;

public class DeviceSettings extends PreferenceFragment implements
        Preference.OnPreferenceChangeListener {

    public static final String KEY_DTAP2WAKE = "dtap2wake";
    public static final String KEY_SWEEP2WAKE = "sweep2wake";
    public static final String KEY_VIBSTRENGTH = "vib_strength";
    public static final String KEY_TORBRIGHTNESS = "tor_brightness";

    private TwoStatePreference mDTapToWakeSwitch;
    private TwoStatePreference mSweepToWakeSwitch;
    private VibratorStrengthPreference mVibratorStrength;
    private TorchBrightnessPreference mTorchBrightness;

    @Override
    public void onCreatePreferences(Bundle savedInstanceState, String rootKey) {
        setPreferencesFromResource(R.xml.main, rootKey);

        mDTapToWakeSwitch = (TwoStatePreference) findPreference(KEY_DTAP2WAKE);
        mDTapToWakeSwitch.setEnabled(DTapToWakeSwitch.isSupported());
        mDTapToWakeSwitch.setChecked(DTapToWakeSwitch.isCurrentlyEnabled(this.getContext()));
        mDTapToWakeSwitch.setOnPreferenceChangeListener(new DTapToWakeSwitch());

        mSweepToWakeSwitch = (TwoStatePreference) findPreference(KEY_SWEEP2WAKE);
        mSweepToWakeSwitch.setEnabled(SweepToWakeSwitch.isSupported());
        mSweepToWakeSwitch.setChecked(SweepToWakeSwitch.isCurrentlyEnabled(this.getContext()));
        mSweepToWakeSwitch.setOnPreferenceChangeListener(new SweepToWakeSwitch());


        mVibratorStrength = (VibratorStrengthPreference) findPreference(KEY_VIBSTRENGTH);
        if (mVibratorStrength != null) {
            mVibratorStrength.setEnabled(VibratorStrengthPreference.isSupported());
        }

        mTorchBrightness = (TorchBrightnessPreference) findPreference(KEY_TORBRIGHTNESS);
        if (mTorchBrightness != null) {
            mTorchBrightness.setEnabled(TorchBrightnessPreference.isSupported());
        }
        
    }

    @Override
    public boolean onPreferenceTreeClick(Preference preference) {
        return super.onPreferenceTreeClick(preference);
    }

    @Override
    public boolean onPreferenceChange(Preference preference, Object newValue) {
        return true;
    }
}
