using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BurningTransitionEffect : MonoBehaviour
{
    [SerializeField]
    private float _burningSpeed = 0.1f;

    private float _burningTime;

    private Material _mat;

    private void Awake()
    {
        var shader = Shader.Find("Hidden/BurningDev");
        _mat = new Material(shader);
    }

    private void Update()
    {
        if (Input.GetKeyUp(KeyCode.R))
        {
            _burningTime = 0;
        }
        _mat.SetFloat("_BurningTime", _burningTime);
        _burningTime += Time.deltaTime * _burningSpeed;
        if (_burningTime > 2)
        {
            _burningTime = 0;
        }
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        Graphics.Blit(src, dst, _mat);
    }
}
