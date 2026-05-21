import type { AvatarKey } from '../../lib/supabase/types'
import { avatarOptions } from './avatarOptions'

type AvatarPickerProps = {
  value: AvatarKey
  onChange: (value: AvatarKey) => void
  disabled?: boolean
}

export function AvatarPicker({
  value,
  onChange,
  disabled = false,
}: AvatarPickerProps) {
  return (
    <fieldset className="avatar-picker">
      <legend>Avatar pré-definido</legend>
      <div className="avatar-grid">
        {avatarOptions.map((option) => (
          <label key={option.key} className="avatar-option">
            <input
              type="radio"
              name="avatar_key"
              value={option.key}
              checked={value === option.key}
              disabled={disabled}
              onChange={() => onChange(option.key)}
            />
            <span className={`profile-avatar avatar-tone-${option.tone}`} aria-hidden="true">
              {option.initials}
            </span>
            <span>{option.label}</span>
          </label>
        ))}
      </div>
    </fieldset>
  )
}
